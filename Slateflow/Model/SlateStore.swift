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
    @ObservationIgnored private let defaults: UserDefaults

    /// Everything the form configures, saved whole on every change.
    private var settings: SavedSettings {
        didSet { settings.save(to: defaults) }
    }

    var choice: ResolutionChoice {
        get { settings.choice } set { settings.choice = newValue }
    }
    /// Setting it snaps `aspect` back into range - see `SavedSettings.orientation`.
    var orientation: Orientation {
        get { settings.orientation } set { settings.orientation = newValue }
    }
    var aspect: AspectRatio {
        get { settings.aspect } set { settings.aspect = newValue }
    }
    var customWidth: Int {
        get { settings.customWidth } set { settings.customWidth = newValue }
    }
    var customHeight: Int {
        get { settings.customHeight } set { settings.customHeight = newValue }
    }
    var templateName: String {
        get { settings.templateName } set { settings.templateName = newValue }
    }
    /// Enabled sources (presets + customs) in insertion order.
    var footageSources: [FootageSource] {
        get { settings.footageSources } set { settings.footageSources = newValue }
    }
    var fcp: FCPLibrarySettings {
        get { settings.fcp } set { settings.fcp = newValue }
    }

    /// Display / build order: enabled presets first (preset order), then customs.
    var orderedFootageSources: [FootageSource] {
        let enabled = Set(footageSources)
        return FootageSource.presets.filter(enabled.contains) + footageSources.filter(\.isCustom)
    }

    let history = SelectionHistory()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded = SavedSettings.load(from: defaults)
        // Keep Smart Collections in sync with the enabled footage sources.
        for source in loaded.footageSources {
            Self.addFootageLinkedCollection(source, to: &loaded.fcp)
        }
        // First assignment runs the init accessor, not `didSet`: building a store writes nothing.
        settings = loaded
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
            Self.addFootageLinkedCollection(source, to: &fcp)
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
    private static func addFootageLinkedCollection(_ source: FootageSource,
                                                   to fcp: inout FCPLibrarySettings) {
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
