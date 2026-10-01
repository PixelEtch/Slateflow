//
//  FCPLibrary.swift
//  Slateflow
//
//  FCP library template: custom roles, Smart Collections, and FCPXML emission.
//

import Foundation

// MARK: - Smart Collections

/// A Smart Collection = a name and one or more rules, all of which must match.
/// Each rule maps to one FCPXML `match-*` element. Rules only bite if the
/// matching signal (role, keyword, metadata) is stamped on the asset at import
/// - see the header notes on each `Rule` case.
struct SmartCollectionSpec: Hashable, Identifiable, Codable {
    enum Rule: Hashable, Codable {
        /// A `match-media` type from the FCPXML DTD, e.g. `videoOnly`, `stills`.
        case mediaType(String)
        /// Assigned role or sub-role ("Video.Screen Recording"). Stamp via Assign Role on import.
        case role(String)
        /// Keyword Collections - e.g. day folders imported with "Keywords: from folders".
        case keywords([String])
        /// Clip name + notes substring. Least stable signal; pair with `mediaType`.
        case text(String)
        /// Inspector ▸ Info metadata, e.g. key "cameraAngle".
        case property(key: String, value: String)

        /// Plain-English description for the UI.
        var summary: String {
            switch self {
            case .mediaType("videoOnly"): return "video clips only"
            case .mediaType("stills"):    return "still images only"
            case .mediaType(let t):       return t
            case .role(let name):         return "has the “\(name)” role"
            case .keywords(let words):    return "keyword " + words.map { "“\($0)”" }.joined(separator: " or ")
            case .text(let value):        return "name contains “\(value)”"
            case .property(let key, let value):
                return "\(key == "cameraAngle" ? "Camera Angle" : key) is “\(value)”"
            }
        }
    }

    var name: String
    var rules: [Rule]
    var enabled = true
    /// True when this collection was generated from an enabled Footage Source and
    /// should be removed if that source is turned off.
    var isFootageLinked = false
    var id: String { name }

    /// One-line description of the whole collection, for the UI and `.help()` tooltip.
    var summary: String {
        rules.map(\.summary).joined(separator: " · and ")
    }

    /// SF Symbol for the list row, chosen from the first rule.
    var iconName: String {
        if isFootageLinked { return "video.fill" }
        switch rules.first {
        case .mediaType("stills"):      return "photo"
        case .mediaType:                return "film"
        case .role:                     return "tag"
        case .keywords:                 return "number"
        case .text:                     return "textformat"
        case .property:                 return "camera"
        case nil:                       return "square.grid.2x2"
        }
    }
}

extension SmartCollectionSpec {
    static func defaults(roles: [String]) -> [SmartCollectionSpec] {
        var specs = [
            SmartCollectionSpec(name: "Footage", rules: [.mediaType("videoOnly")]),
            SmartCollectionSpec(name: "Stills",  rules: [.mediaType("stills")]),
            SmartCollectionSpec(name: "Screen Recordings",
                                rules: [.mediaType("videoOnly"), .text("Screen Recording")]),
        ]
        // One collection per role, skipping any name already taken (e.g. "Footage").
        let taken = Set(specs.map(\.name))
        specs += roles
            .filter { !taken.contains($0) }
            .map { SmartCollectionSpec(name: $0, rules: [.role($0)]) }
        return specs
    }
}

// MARK: - Frame rate

/// Project frame rate. Whole-number rates map to a plain `1/Ns` FCPXML frame
/// duration; the NTSC rates use the standard SMPTE drop-frame fraction
/// (24000/1001 ≈ 23.98, 30000/1001 ≈ 29.97, 60000/1001 ≈ 59.94).
nonisolated enum FrameRate: Double, CaseIterable, Identifiable {
    case fps23_98 = 23.98
    case fps24    = 24
    case fps25    = 25
    case fps29_97 = 29.97
    case fps30    = 30
    case fps50    = 50
    case fps59_94 = 59.94
    case fps60    = 60
    var id: Double { rawValue }

    var label: String {
        switch self {
        case .fps23_98: "23.98 fps"
        case .fps24:    "24 fps"
        case .fps25:    "25 fps"
        case .fps29_97: "29.97 fps"
        case .fps30:    "30 fps"
        case .fps50:    "50 fps"
        case .fps59_94: "59.94 fps"
        case .fps60:    "60 fps"
        }
    }

    /// FCPXML `frameDuration` fraction for this rate.
    var frameDurationFCPX: String {
        switch self {
        case .fps23_98: "1001/24000s"
        case .fps24:    "1/24s"
        case .fps25:    "1/25s"
        case .fps29_97: "1001/30000s"
        case .fps30:    "1/30s"
        case .fps50:    "1/50s"
        case .fps59_94: "1001/60000s"
        case .fps60:    "1/60s"
        }
    }
}

// MARK: - Library settings

struct FCPLibrarySettings {
    /// "Leave files in place" - media stays in the project folders, not copied into the library.
    var keepMediaInPlace = true
    var frameRate: FrameRate = .fps25
    static let defaultVideoRoles = ["Footage", "Graphics", "Titles"]
    static let defaultAudioRoles = ["Dialogue", "Music", "Effects"]

    var videoRoles = defaultVideoRoles
    var audioRoles = defaultAudioRoles
    var smartCollections = SmartCollectionSpec.defaults(roles: defaultVideoRoles + defaultAudioRoles)

    /// Write `<event>.fcpxml` (and an import note when media is kept in place) into `fcpFolder`.
    nonisolated func write(into fcpFolder: URL, format: VideoFormat, eventName: String) throws {
        try FileManager.default.createDirectory(
            at: fcpFolder, withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.directory])

        let xmlURL = fcpFolder.appendingPathComponent("\(eventName).fcpxml")
        let libraryURL = fcpFolder.appendingPathComponent("\(eventName).fcpbundle", isDirectory: true)
        let xml = FCPXML.document(settings: self, format: format, eventName: eventName,
                                  libraryLocation: libraryURL)
        try xml.write(to: xmlURL, atomically: true, encoding: .utf8)
        FilePermissions.harden(file: xmlURL)

        guard keepMediaInPlace else { return }
        // No FCPXML attribute controls this - it's an import-time preference. Leave a note.
        let note = """
        # Import settings

        This template keeps media outside the FCP library. Before importing
        \(eventName).fcpxml or any media, enable:

        Final Cut Pro ▸ Settings ▸ Import ▸ Files: **Leave files in place**

        Media lives alongside this folder: ../Footage, ../Audio, ../Graphics, ../Images.
        """
        let noteURL = fcpFolder.appendingPathComponent("Import Settings.md")
        try note.write(to: noteURL, atomically: true, encoding: .utf8)
        FilePermissions.harden(file: noteURL)
    }
}

// MARK: - FCPXML

nonisolated enum FCPXML {
    /// Minimal FCPXML 1.11: a spatial `<format>` + an empty `<project>` at the chosen
    /// resolution/orientation, plus role- and media-type Smart Collections in the event.
    /// FCP creates any referenced custom role on import.
    // Verified against a real "Export XML" from Final Cut Pro (1.14): its <format> carries
    // colorSpace, and its <sequence> carries audioLayout/audioRate - both #IMPLIED per the
    // DTD (so structurally optional) but expected by FCP's importer for a project sequence.
    /// `libraryLocation`: where the library should live. When nothing exists there yet,
    /// FCP asks which library to import into, and its New… panel opens in that folder -
    /// so the library FCP creates is always the installed FCP's version.
    static func document(settings: FCPLibrarySettings, format: VideoFormat, eventName: String,
                         libraryLocation: URL? = nil) -> String {
        let collections = settings.smartCollections
            .filter(\.enabled)
            .map { collection($0) }
            .joined(separator: "\n")
        let formatName = "Slate \(format.width)×\(format.height)"
        let library = libraryLocation.map { #"<library location="\#(escape($0.absoluteString))">"# } ?? "<library>"
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
        <resources>
        <format id="r1" name="\(escape(formatName))" width="\(format.width)" height="\(format.height)" frameDuration="\(settings.frameRate.frameDurationFCPX)" colorSpace="1-1-1 (Rec. 709)"/>
        </resources>
        \(library)
        <event name="\(escape(eventName))">
        <project name="\(escape(eventName))">
        <sequence format="r1" duration="0s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
        <spine/>
        </sequence>
        </project>
        \(collections)
        </event>
        </library>
        </fcpxml>
        """
    }

    private static func collection(_ spec: SmartCollectionSpec) -> String {
        let body = spec.rules.map { rule($0) }.joined(separator: "\n")
        return """
        <smart-collection name="\(escape(spec.name))" match="all">
        \(body)
        </smart-collection>
        """
    }

    private static func rule(_ rule: SmartCollectionSpec.Rule) -> String {
        switch rule {
        case .mediaType(let type):
            return #"<match-media rule="is" type="\#(type)"/>"#
        case .role(let name):
            return """
            <match-roles rule="includesAny">
            <role name="\(escape(name))"/>
            </match-roles>
            """
        case .keywords(let words):
            // `keyword-name` is EMPTY per the DTD - the text goes in `value`, not as content.
            let items = words.map { #"<keyword-name value="\#(escape($0))"/>"# }.joined(separator: "\n")
            return """
            <match-keywords rule="includesAny">
            \(items)
            </match-keywords>
            """
        case .text(let value):
            return #"<match-text rule="includes" value="\#(escape(value))"/>"#
        case .property(let key, let value):
            return #"<match-property key="\#(escape(key))" type="string" value="\#(escape(value))" rule="is" enabled="1"/>"#
        }
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
