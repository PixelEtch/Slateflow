//
//  ProjectManifest.swift
//  Slateflow
//
//  Self-documenting JSON written into every built project folder.
//

import Foundation

/// Written to `<root>/Slate Project.json` so the template folder self-documents.
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
    var videoRoles: [String]
    var audioRoles: [String]
    var smartCollections: [String]
    var footageSources: [String]

    @MainActor
    init(store: SlateStore, root: String) {
        template = root
        created = Date()
        resolution = store.choice.rawValue
        orientation = store.choice == .custom ? "-" : store.orientation.rawValue
        aspect = store.choice == .custom ? store.format.aspectRatio : store.aspect.rawValue
        width = store.format.width
        height = store.format.height
        aspectRatio = store.format.aspectRatio
        frameRate = store.fcp.frameRate.label
        leaveFilesInPlace = store.fcp.keepMediaInPlace
        videoRoles = store.fcp.videoRoles.map(\.name)
        audioRoles = store.fcp.audioRoles.map(\.name)
        smartCollections = store.fcp.smartCollections.filter(\.enabled).map(\.name)
        footageSources = store.orderedFootageSources.map(\.folderName)
    }

    nonisolated func write(to rootFolder: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let url = rootFolder.appendingPathComponent("Slate Project.json")
        try enc.encode(self).write(to: url, options: .atomic)
        FilePermissions.harden(file: url)
    }
}
