//
//  ProjectManifest.swift
//  Slateflow
//
//  Self-documenting JSON written into every built project folder.
//

import Foundation

/// Written to `<root>/.slateflow.json` (hidden in Finder) so the project self-documents.
/// Built from the same `BuildSnapshot` as the folders and the Build Archives entry.
nonisolated struct ProjectManifest: Codable {
    var template: String
    var created: Date
    var resolution: String
    var orientation: String
    var aspect: String
    var width: Int
    var height: Int
    var aspectRatio: String
    var frameRate: String
    var leaveFilesInPlace: Bool
    var colorSpace: String
    /// The extra 9:16 timeline's size, e.g. "2160 × 3840"; nil when none was built.
    var reelTimeline: String?
    var videoRoles: [String]
    var audioRoles: [String]
    var smartCollections: [String]
    var footageSources: [String]

    init(snapshot s: BuildSnapshot, root: String) {
        template = root
        created = Date()
        resolution = s.choice.rawValue
        orientation = s.orientationLabel
        aspect = s.choice == .custom ? s.format.aspectRatio : s.aspect.rawValue
        width = s.format.width
        height = s.format.height
        aspectRatio = s.format.aspectRatio
        frameRate = s.fcp.frameRate.label
        leaveFilesInPlace = s.fcp.keepMediaInPlace
        colorSpace = s.fcp.colorSpace.label
        reelTimeline = s.reelFormat?.pixelDimensions
        videoRoles = s.fcp.videoRoles
        audioRoles = s.fcp.audioRoles
        smartCollections = s.fcp.smartCollections.filter(\.enabled).map(\.name)
        footageSources = s.footageSources.map(\.folderName)
    }

    func write(to rootFolder: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let url = rootFolder.appendingPathComponent(ProjectLayout.manifestFile)
        try enc.encode(self).write(to: url, options: .atomic)
    }
}
