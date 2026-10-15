//
//  SavedSettings.swift
//  Slateflow
//
//  The form state that persists across launches, loaded and saved as one value.
//

import Foundation

/// Everything the form configures. `SlateStore` loads it once in `init` and saves
/// the whole value on every change, so restore order can't matter and building a
/// store writes nothing. Keys and formats match earlier releases' per-field saves.
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
    /// Enabled sources (presets + customs) in insertion order. Saved by name.
    var footageSources: [FootageSource] = [.camA, .camB]
    var fcp = FCPLibrarySettings()

    private enum Key {
        static let choice = "choice", orientation = "orientation", aspect = "aspect"
        static let customWidth = "customWidth", customHeight = "customHeight"
        static let templateName = "templateName", keepMediaInPlace = "keepMediaInPlace"
        static let frameRate = "frameRate", footageSources = "footageSources"
        static let videoRoles = "videoRoles", audioRoles = "audioRoles"
        static let smartCollections = "smartCollections"
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
        return s
    }

    // ponytail: rewrites every key on any change - a few small values and one short
    // JSON array; diff against the last save if collections ever grow large.
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
    }
}
