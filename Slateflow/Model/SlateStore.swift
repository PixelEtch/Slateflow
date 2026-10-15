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
    // Everything the form configures persists across launches.
    private enum Key {
        static let choice = "choice", orientation = "orientation", aspect = "aspect"
        static let customWidth = "customWidth", customHeight = "customHeight"
        static let templateName = "templateName", keepMediaInPlace = "keepMediaInPlace"
        static let frameRate = "frameRate", footageSources = "footageSources"
        static let videoRoles = "videoRoles", audioRoles = "audioRoles"
        static let smartCollections = "smartCollections"
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
    var templateName = ProjectLayout.defaultTemplateName {
        didSet { defaults.set(templateName, forKey: Key.templateName) }
    }
    /// Enabled sources (presets + customs) in insertion order. Saved by name.
    var footageSources: [FootageSource] = [.camA, .camB] {
        didSet { defaults.set(footageSources.map(\.folderName), forKey: Key.footageSources) }
    }
    // ponytail: rewrites every fcp field on any change - a few small values and one
    // short JSON array; split per field if collections ever grow large.
    var fcp = FCPLibrarySettings() {
        didSet {
            defaults.set(fcp.keepMediaInPlace, forKey: Key.keepMediaInPlace)
            defaults.set(fcp.frameRate.rawValue, forKey: Key.frameRate)
            defaults.set(fcp.videoRoles, forKey: Key.videoRoles)
            defaults.set(fcp.audioRoles, forKey: Key.audioRoles)
            defaults.set(try? JSONEncoder().encode(fcp.smartCollections), forKey: Key.smartCollections)
        }
    }

    /// Display / build order: enabled presets first (preset order), then customs.
    var orderedFootageSources: [FootageSource] {
        let enabled = Set(footageSources)
        return FootageSource.presets.filter(enabled.contains) + footageSources.filter(\.isCustom)
    }

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
        // Restore into a copy and assign once: each `fcp` assignment saves every fcp
        // field, so piecemeal assignment would overwrite not-yet-read values.
        var saved = fcp
        if d.object(forKey: Key.frameRate) != nil,
           let rate = FrameRate(rawValue: d.double(forKey: Key.frameRate)) {
            saved.frameRate = rate
        }
        if d.object(forKey: Key.keepMediaInPlace) != nil {
            saved.keepMediaInPlace = d.bool(forKey: Key.keepMediaInPlace)
        }
        if let roles = d.stringArray(forKey: Key.videoRoles) { saved.videoRoles = roles }
        if let roles = d.stringArray(forKey: Key.audioRoles) { saved.audioRoles = roles }
        if let data = d.data(forKey: Key.smartCollections),
           let specs = try? JSONDecoder().decode([SmartCollectionSpec].self, from: data) {
            saved.smartCollections = specs
        }
        fcp = saved
        if let names = d.stringArray(forKey: Key.footageSources) {
            footageSources = names.map { name in
                FootageSource.presets.first { $0.folderName == name } ?? .custom(name)
            }
        }

        // Keep Smart Collections in sync with the enabled footage sources.
        for source in footageSources {
            addFootageLinkedCollection(source)
        }
    }

    /// Display name before a destination is picked: the `NNN` prefix depends on the
    /// numbered folders already there, so it is only known at build time.
    var rootFolderName: String { ProjectLayout.pendingRootName(template: safeTemplateName) }

    /// `templateName` sanitised to a single safe path component (no separators,
    /// no `..`) so it can never escape the chosen destination.
    var safeTemplateName: String {
        SafeName.component(templateName, fallback: ProjectLayout.defaultTemplateName)
    }

    /// Derived live from (choice, aspect, custom dimensions) - no stored copy,
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
    // successful build - see `buildProject(at:)`.

    /// Reapply a past build's format, naming, and leave-in-place setting - what
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
        templateName = ProjectLayout.parse(rootName: record.rootFolder)?.template ?? record.rootFolder
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

    /// Add a user-named source (Lumix, Blackmagic, …). The name is sanitised to a safe
    /// path component; a preset's name enables that preset; no-op on blank or
    /// case-insensitive duplicate.
    func addCustomFootageSource(_ name: String) {
        let safe = SafeName.component(name, fallback: "")
        if let preset = FootageSource.presets.first(where: {
            $0.folderName.caseInsensitiveCompare(safe) == .orderedSame
        }) {
            return setFootageSource(preset, enabled: true)
        }
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

    /// Removes the linked collection only - a manually-added collection of the same name stays.
    private func removeFootageLinkedCollection(_ source: FootageSource) {
        fcp.smartCollections.removeAll { $0.isFootageLinked && $0.name == source.folderName }
    }

    /// Add a custom role to `roles` (`\.videoRoles` or `\.audioRoles`) and a matching
    /// role-based Smart Collection.
    func addRole(name: String, to roles: WritableKeyPath<FCPLibrarySettings, [String]>) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !fcp[keyPath: roles].contains(trimmed) else { return }
        fcp[keyPath: roles].append(trimmed)
        addCollection(SmartCollectionSpec(name: trimmed, rules: [.role(trimmed)]))
    }

    enum QuickCollection {
        case cameraAngle    // Inspector ▸ Info ▸ Camera Angle
        case keyword        // also day folders imported as Keyword Collections
        case nameContains   // + videoOnly, for screen recordings etc.
    }

    /// Add a parameterised Smart Collection for the common filtering axes.
    func addQuickCollection(_ kind: QuickCollection, value: String) {
        let v = value.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        let spec: SmartCollectionSpec
        switch kind {
        case .cameraAngle:  spec = .init(name: v, rules: [.property(key: "cameraAngle", value: v)])
        case .keyword:      spec = .init(name: v, rules: [.keywords([v])])
        case .nameContains: spec = .init(name: v, rules: [.mediaType("videoOnly"), .text(v)])
        }
        addCollection(spec)
    }

    func removeCollection(_ spec: SmartCollectionSpec) {
        // A single-rule role collection owns its role - drop both together.
        if spec.rules.count == 1, case .role(let name) = spec.rules[0] {
            fcp.videoRoles.removeAll { $0 == name }
            fcp.audioRoles.removeAll { $0 == name }
        }
        fcp.smartCollections.removeAll { $0.id == spec.id }
    }

    /// Append unless a collection with the same name already exists.
    private func addCollection(_ spec: SmartCollectionSpec) {
        guard !fcp.smartCollections.contains(where: { $0.name == spec.name }) else { return }
        fcp.smartCollections.append(spec)
    }

    /// Build the next numbered project in `destination` from one snapshot of the
    /// current configuration, then record that same snapshot in Build Archives.
    @discardableResult
    func buildProject(at destination: URL) async throws -> URL {
        let snapshot = snapshot
        // Disk writes run off the main actor so the window stays responsive on slow volumes.
        let rootURL = try await Task.detached(priority: .userInitiated) {
            try ProjectLayout.build(snapshot, in: destination)
        }.value
        // Only a successful build records history - the final locked-in state.
        history.record(BuildRecord(snapshot: snapshot, rootFolder: rootURL.lastPathComponent))
        return rootURL
    }
}
