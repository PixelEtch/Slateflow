//
//  SlateStore.swift
//  Slateflow
//
//  The app's single source of truth: configuration state + the build intent.
//

import Foundation

@MainActor
@Observable
final class SlateStore {
    // Format + naming persist across launches; structural choices (sources, roles,
    // collections) stay at their sensible defaults.
    private enum Key {
        static let choice = "choice", orientation = "orientation", aspect = "aspect"
        static let customWidth = "customWidth", customHeight = "customHeight"
        static let templateName = "templateName", keepMediaInPlace = "keepMediaInPlace"
        static let frameRate = "frameRate"
    }
    @ObservationIgnored private let defaults: UserDefaults

    var choice: ResolutionChoice = .uhd4k {
        didSet { defaults.set(choice.rawValue, forKey: Key.choice) }
    }
    var orientation: Orientation = .landscape {
        didSet {
            defaults.set(orientation.rawValue, forKey: Key.orientation)
            // Snap the aspect ratio back into range for the new orientation.
            if !orientation.ratios.contains(aspect) { aspect = orientation.defaultRatio }
        }
    }
    var aspect: AspectRatio = .wide169 {
        didSet { defaults.set(aspect.rawValue, forKey: Key.aspect) }
    }
    var customWidth = 3840 {
        didSet { defaults.set(customWidth, forKey: Key.customWidth) }
    }
    var customHeight = 2160 {
        didSet { defaults.set(customHeight, forKey: Key.customHeight) }
    }
    var templateName = ProjectNaming.defaultTemplateName {
        didSet { defaults.set(templateName, forKey: Key.templateName) }
    }
    /// Enabled sources (presets + customs) in insertion order.
    var footageSources: [FootageSource] = [.camA, .camB]
    // ponytail: only keepMediaInPlace + frameRate persist; fires on any fcp change,
    // which is two cheap scalar writes.
    var fcp = FCPLibrarySettings() {
        didSet {
            defaults.set(fcp.keepMediaInPlace, forKey: Key.keepMediaInPlace)
            defaults.set(fcp.frameRate.rawValue, forKey: Key.frameRate)
        }
    }

    /// Display / build order: enabled presets first (preset order), then customs.
    var orderedFootageSources: [FootageSource] {
        let enabled = Set(footageSources)
        return FootageSource.presets.filter(enabled.contains) + footageSources.filter(\.isCustom)
    }

    /// Filled in when a build target is chosen; drives the folder prefix.
    private(set) var sequence = 1

    let history = SelectionHistory()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Restore the last-used format + naming.
        let d = defaults
        if let raw = d.string(forKey: Key.choice), let c = ResolutionChoice(rawValue: raw) { choice = c }
        if let raw = d.string(forKey: Key.orientation), let o = Orientation(rawValue: raw) { orientation = o }
        if let raw = d.string(forKey: Key.aspect), let a = AspectRatio(rawValue: raw),
           orientation.ratios.contains(a) { aspect = a }
        if d.object(forKey: Key.customWidth) != nil { customWidth = d.integer(forKey: Key.customWidth) }
        if d.object(forKey: Key.customHeight) != nil { customHeight = d.integer(forKey: Key.customHeight) }
        if let name = d.string(forKey: Key.templateName), !name.isEmpty { templateName = name }
        if d.object(forKey: Key.frameRate) != nil,
           let rate = FrameRate(rawValue: d.double(forKey: Key.frameRate)) {
            fcp.frameRate = rate
        }
        if d.object(forKey: Key.keepMediaInPlace) != nil {
            fcp.keepMediaInPlace = d.bool(forKey: Key.keepMediaInPlace)
        }

        // Keep Smart Collections in sync with the footage sources enabled by default.
        for source in footageSources {
            addFootageLinkedCollection(source)
        }
    }

    /// Live-derived from `templateName`, sanitised to a single safe path component
    /// (no separators, no `..`) so it can never escape the chosen destination.
    var rootFolderName: String {
        let safe = SafeName.component(templateName, fallback: ProjectNaming.defaultTemplateName)
        return FolderName(sequence: sequence, templateName: safe).formatted
    }

    /// Derived live from (choice, aspect, custom dimensions) — no stored copy,
    /// so binding the controls straight to `choice` / `aspect` / `customWidth`
    /// keeps the output size and preview in sync with no "apply" step.
    var format: VideoFormat {
        if let preset = choice.preset { return aspect.apply(to: preset) }
        return .custom(width: customWidth, height: customHeight)
    }

    /// Non-nil when the typed custom dimensions will be corrected on build.
    var customDimensionsIssue: DimensionIssue? {
        guard choice == .custom else { return nil }
        if customWidth < 2 || customHeight < 2 { return .tooSmall }
        if !customWidth.isMultiple(of: 2) || !customHeight.isMultiple(of: 2) { return .odd }
        return nil
    }

    // Intents mutate configuration only. Nothing is written to `history` until a
    // successful build — see `buildProject(at:)`.

    /// Reapply a past build's format, naming, and leave-in-place setting — what
    /// "Build Archives" is actually for. Roles, Smart Collections, and footage
    /// sources aren't restored: only their counts were ever recorded.
    func applyConfiguration(from record: BuildRecord) {
        guard let restoredChoice = ResolutionChoice(rawValue: record.resolution) else { return }
        choice = restoredChoice

        if choice == .custom {
            customWidth = record.width
            customHeight = record.height
        } else if let restoredOrientation = Orientation(rawValue: record.orientation) {
            orientation = restoredOrientation
            if let restoredAspect = AspectRatio(rawValue: record.aspectRawValue),
               orientation.ratios.contains(restoredAspect) {
                aspect = restoredAspect
            }
        }

        if let rate = FrameRate(rawValue: record.frameRateValue) {
            fcp.frameRate = rate
        }
        fcp.keepMediaInPlace = record.leaveFilesInPlace
        templateName = Self.templateName(from: record.rootFolder)
    }

    /// Strips the fixed `"NNN - "` sequence prefix `FolderName.formatted` always adds.
    private static func templateName(from rootFolder: String) -> String {
        guard rootFolder.count > 6 else { return rootFolder }
        return String(rootFolder.dropFirst(6))
    }

    func setFootageSource(_ source: FootageSource, enabled: Bool) {
        if enabled {
            guard !footageSources.contains(source) else { return }
            footageSources.append(source)
            addFootageLinkedCollection(source)
        } else {
            footageSources.removeAll { $0 == source }
            removeFootageLinkedCollection(source)
        }
    }

    /// Add a user-named source (Insta360, Lumix, …). The name is sanitised to a safe
    /// path component; no-op on blank or case-insensitive duplicate.
    func addCustomFootageSource(_ name: String) {
        let safe = SafeName.component(name, fallback: "")
        guard !safe.isEmpty,
              !footageSources.contains(where: {
                  $0.folderName.caseInsensitiveCompare(safe) == .orderedSame
              }) else { return }
        setFootageSource(.custom(safe), enabled: true)
    }

    /// A Smart Collection that matches the FCP keyword created when the source's
    /// `Footage/<name>` folder is imported with “Keywords: from folders”.
    private func addFootageLinkedCollection(_ source: FootageSource) {
        let name = source.folderName
        guard !fcp.smartCollections.contains(where: { $0.name == name }) else { return }
        var spec = SmartCollectionSpec(name: name, rules: [.keywords([name])])
        spec.isFootageLinked = true
        fcp.smartCollections.append(spec)
    }

    /// Removes the linked collection only — a manually-added collection of the same name stays.
    private func removeFootageLinkedCollection(_ source: FootageSource) {
        fcp.smartCollections.removeAll { $0.isFootageLinked && $0.name == source.folderName }
    }

    /// Add a custom role and a matching role-based Smart Collection.
    func addRole(name: String, kind: MediaRole.Kind) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let role = MediaRole(name: trimmed, kind: kind)
        switch kind {
        case .video where !fcp.videoRoles.contains(role): fcp.videoRoles.append(role)
        case .audio where !fcp.audioRoles.contains(role): fcp.audioRoles.append(role)
        default: return
        }
        addCollection(SmartCollectionSpec(name: trimmed, rules: [.role(trimmed)]))
    }

    enum QuickCollection: String, CaseIterable, Identifiable {
        case cameraAngle = "Camera Angle"   // Inspector ▸ Info ▸ Camera Angle
        case day = "Day"                    // folder imported as Keyword Collection
        case keyword = "Keyword"
        case nameContains = "Name contains" // + videoOnly, for screen recordings etc.
        var id: String { rawValue }
    }

    /// Add a parameterised Smart Collection for the common filtering axes.
    func addQuickCollection(_ kind: QuickCollection, value: String) {
        let v = value.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        let spec: SmartCollectionSpec
        switch kind {
        case .cameraAngle:  spec = .init(name: v, rules: [.property(key: "cameraAngle", value: v)])
        case .day, .keyword: spec = .init(name: v, rules: [.keywords([v])])
        case .nameContains: spec = .init(name: v, match: .all,
                                         rules: [.mediaType("videoOnly"), .text(v)])
        }
        addCollection(spec)
    }

    func removeCollection(_ spec: SmartCollectionSpec) {
        // A single-rule role collection owns its role — drop both together.
        if spec.rules.count == 1, case .role(let name, _) = spec.rules[0] {
            fcp.videoRoles.removeAll { $0.name == name }
            fcp.audioRoles.removeAll { $0.name == name }
        }
        fcp.smartCollections.removeAll { $0.id == spec.id }
    }

    /// Append unless a collection with the same name already exists. Returns whether it was added.
    @discardableResult
    private func addCollection(_ spec: SmartCollectionSpec) -> Bool {
        guard !fcp.smartCollections.contains(where: { $0.name == spec.name }) else { return false }
        fcp.smartCollections.append(spec)
        return true
    }

    /// Create the full directory hierarchy under `destination`, named `NNN - <template>`,
    /// write the FCP library template (`<root>/FCP/…`) and the manifest, then record history.
    @discardableResult
    func buildProject(at destination: URL) async throws -> URL {
        sequence = ProjectNaming.nextSequence(in: destination)
        let root = rootFolderName
        let rootURL = destination.appendingPathComponent(root)

        // Backstop: even with `root` sanitised, refuse to write outside the chosen folder.
        guard rootURL.isContained(in: destination) else {
            Log.error("Refused build: “\(root)” resolves outside \(destination.path)")
            throw SlateError.destinationEscape(root)
        }
        // Never merge into (or follow a symlink at) a folder that already exists —
        // build into a fresh directory only.
        guard !FileManager.default.fileExists(atPath: rootURL.path) else {
            Log.error("Refused build: “\(root)” already exists at the destination")
            throw SlateError.destinationOccupied(root)
        }
        Log.event("Build started: “\(root)” → \(destination.path)")

        // Snapshot the configuration, then run the disk writes off the main actor so
        // the window stays responsive on slow or network volumes.
        let tree = DirectoryNode.slateTemplate(root: root, footageSources: orderedFootageSources)
        let sourceCount = orderedFootageSources.count
        let settings = fcp
        let fmt = format
        let manifest = ProjectManifest(store: self, root: root)

        do {
            try await Task.detached(priority: .userInitiated) {
                // Recursively creates <root> and every nested subfolder, including the
                // fixed Admin set and only the selected Footage sources.
                try tree.write(into: destination)
                Log.event("Directory tree written (\(sourceCount) footage sources)")

                try settings.write(into: rootURL.appendingPathComponent("FCP"), format: fmt, eventName: root)
                Log.event("FCPXML + import notes written to \(root)/FCP")

                do {
                    if try LibraryTemplate.copy(into: rootURL.appendingPathComponent("FCP"), eventName: root) != nil {
                        Log.event("Library template copied to \(root)/FCP")
                    }
                } catch {
                    // Non-fatal: the fcpxml-only flow still works without a pre-made library.
                    Log.error("Library template copy skipped: \(error.localizedDescription)")
                }

                try manifest.write(to: rootURL)
                Log.event("Manifest written; build complete: “\(root)”")
            }.value
        } catch {
            Log.error("Build failed for “\(root)”: \(error.localizedDescription)")
            throw error
        }

        // Only a successful build records history — the final locked-in state.
        history.record(BuildRecord(store: self))
        return rootURL
    }
}
