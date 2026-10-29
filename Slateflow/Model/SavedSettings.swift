//
//  SavedSettings.swift
//  Slateflow
//
//  The form state that persists across launches, its rules, and what derives from it.
//

import Foundation

/// Everything the form configures, and the rules that keep it consistent. `SlateStore`
/// loads it once in `init` and saves the whole value on every change, so restore order
/// can't matter and building a store writes nothing. Keys and formats match earlier
/// releases' per-field saves.
struct SavedSettings {
    var choice: ResolutionChoice = .uhd4k
    var orientation: Orientation = .landscape {
        // Snap the aspect ratio back into range for the new orientation.
        didSet { if !orientation.ratios.contains(aspect) { aspect = orientation.defaultRatio } }
    }
    var aspect: AspectRatio = .wide169
    var customWidth = 3840
    var customHeight = 2160
    var templateName = ProjectLayout.defaultTemplateName
    /// Enabled sources (presets + customs) in insertion order. Saved by name. Changed only
    /// through `setFootageSource` / `addCustomFootageSource`, which keep the linked
    /// Smart Collections in step.
    private(set) var footageSources: [FootageSource] = [.camA, .camB]
    var fcp = FCPLibrarySettings()
    /// The editable part of the Project Layout, as `/`-separated paths. Changed only
    /// through `addFolder` / `removeFolder` / `resetFolders`, which sanitise each path.
    private(set) var folders = ProjectLayout.defaultFolders

    init() { linkFootageSources() }

    private enum Key {
        static let choice = "choice", orientation = "orientation", aspect = "aspect"
        static let customWidth = "customWidth", customHeight = "customHeight"
        static let templateName = "templateName", keepMediaInPlace = "keepMediaInPlace"
        static let frameRate = "frameRate", footageSources = "footageSources"
        static let videoRoles = "videoRoles", audioRoles = "audioRoles"
        static let smartCollections = "smartCollections", folders = "folders"
    }

    /// Saved values where present and valid, defaults otherwise.
    static func load(from d: UserDefaults) -> SavedSettings {
        var s = SavedSettings()
        if let raw = d.string(forKey: Key.choice), let c = ResolutionChoice(rawValue: raw) { s.choice = c }
        if let raw = d.string(forKey: Key.orientation), let o = Orientation(rawValue: raw) { s.orientation = o }
        if let raw = d.string(forKey: Key.aspect), let a = AspectRatio(rawValue: raw),
           s.orientation.ratios.contains(a) { s.aspect = a }
        if d.object(forKey: Key.customWidth) != nil { s.customWidth = d.integer(forKey: Key.customWidth) }
        if d.object(forKey: Key.customHeight) != nil { s.customHeight = d.integer(forKey: Key.customHeight) }
        if let name = d.string(forKey: Key.templateName), !name.isEmpty { s.templateName = name }
        if let names = d.stringArray(forKey: Key.footageSources) {
            s.footageSources = names.map { name in
                FootageSource.presets.first { $0.folderName == name } ?? .custom(name)
            }
        }
        if d.object(forKey: Key.frameRate) != nil,
           let rate = FrameRate(rawValue: d.double(forKey: Key.frameRate)) {
            s.fcp.frameRate = rate
        }
        if d.object(forKey: Key.keepMediaInPlace) != nil {
            s.fcp.keepMediaInPlace = d.bool(forKey: Key.keepMediaInPlace)
        }
        if let roles = d.stringArray(forKey: Key.videoRoles) { s.fcp.videoRoles = roles }
        if let roles = d.stringArray(forKey: Key.audioRoles) { s.fcp.audioRoles = roles }
        if let data = d.data(forKey: Key.smartCollections),
           let specs = try? JSONDecoder().decode([SmartCollectionSpec].self, from: data) {
            s.fcp.smartCollections = specs
        }
        if let paths = d.stringArray(forKey: Key.folders) {
            s.folders = paths.compactMap { ProjectLayout.folderComponents($0)?.joined(separator: "/") }
        }
        s.linkFootageSources()
        return s
    }

    // shortcut: rewrites every key on any change - fine for a few small values and one
    // short JSON array; diff against the last save if collections ever grow large.
    func save(to d: UserDefaults) {
        d.set(choice.rawValue, forKey: Key.choice)
        d.set(orientation.rawValue, forKey: Key.orientation)
        d.set(aspect.rawValue, forKey: Key.aspect)
        d.set(customWidth, forKey: Key.customWidth)
        d.set(customHeight, forKey: Key.customHeight)
        d.set(templateName, forKey: Key.templateName)
        d.set(footageSources.map(\.folderName), forKey: Key.footageSources)
        d.set(fcp.keepMediaInPlace, forKey: Key.keepMediaInPlace)
        d.set(fcp.frameRate.rawValue, forKey: Key.frameRate)
        d.set(fcp.videoRoles, forKey: Key.videoRoles)
        d.set(fcp.audioRoles, forKey: Key.audioRoles)
        d.set(try? JSONEncoder().encode(fcp.smartCollections), forKey: Key.smartCollections)
        d.set(folders, forKey: Key.folders)
    }
}

// MARK: - Rules

extension SavedSettings {
    /// Display / build order: enabled presets first (preset order), then customs.
    var orderedFootageSources: [FootageSource] {
        let enabled = Set(footageSources)
        return FootageSource.presets.filter(enabled.contains) + footageSources.filter(\.isCustom)
    }

    /// `templateName` sanitised to a single safe path component (no separators,
    /// no `..`) so it can never escape the chosen destination.
    var safeTemplateName: String {
        SafeName.component(templateName, fallback: ProjectLayout.defaultTemplateName)
    }

    /// Display name before a destination is picked: the `NNN` prefix depends on the
    /// numbered folders already there, so it is only known at build time.
    var rootFolderName: String { ProjectLayout.pendingRootName(template: safeTemplateName) }

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
        if min(customWidth, customHeight) < VideoFormat.minimumSide { return .tooSmall }
        if !customWidth.isMultiple(of: 2) || !customHeight.isMultiple(of: 2) { return .odd }
        return nil
    }

    /// Reapply a past build's format, naming, and leave-in-place setting - what
    /// "Build Archives" is actually for. Roles, Smart Collections, and footage
    /// sources aren't restored: only their counts were ever recorded.
    mutating func applyConfiguration(from record: BuildRecord) {
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

    mutating func setFootageSource(_ source: FootageSource, enabled: Bool) {
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
    mutating func addCustomFootageSource(_ name: String) {
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

    /// Add a folder path such as `Admin/Contracts`. Each part is sanitised; no-op when
    /// blank, under a folder Slateflow owns, or already in the tree (any case).
    mutating func addFolder(_ path: String) {
        guard let path = ProjectLayout.folderComponents(path)?.joined(separator: "/") else { return }
        let existing = folders.map { $0.lowercased() }
        guard !existing.contains(where: { $0 == path.lowercased() || $0.hasPrefix(path.lowercased() + "/") })
        else { return }
        folders.append(path)
    }

    mutating func removeFolder(_ path: String) { folders.removeAll { $0 == path } }

    mutating func resetFolders() { folders = ProjectLayout.defaultFolders }

    /// Every enabled source gets its linked Smart Collection (skipped when one covers it).
    private mutating func linkFootageSources() {
        for source in footageSources { fcp.linkFootageSource(source.folderName) }
    }
}
