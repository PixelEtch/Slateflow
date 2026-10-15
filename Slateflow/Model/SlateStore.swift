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

    let history: SelectionHistory

    init(defaults: UserDefaults = .standard, history: SelectionHistory = SelectionHistory()) {
        self.defaults = defaults
        self.history = history
        var loaded = SavedSettings.load(from: defaults)
        // Keep Smart Collections in sync with the enabled footage sources.
        for source in loaded.footageSources {
            loaded.fcp.linkFootageSource(source.folderName)
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
            fcp.linkFootageSource(source.folderName)
        } else {
            footageSources.removeAll { $0 == source }
            fcp.unlinkFootageSource(source.folderName)
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
