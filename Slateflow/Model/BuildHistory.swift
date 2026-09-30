//
//  BuildHistory.swift
//  Slateflow
//
//  Build Archives: a locked-in snapshot per successful build, persisted to disk.
//

import Foundation

/// A locked-in snapshot of the configuration, captured only when a build succeeds.
/// This is what "Build Archives" actually is: a library of past project
/// *configurations* to reuse - not a record of where anything was written.
/// Roles/collections/footage sources are counted for display only; their exact
/// names were never captured, so `SlateStore.applyConfiguration` can't restore them.
struct BuildRecord: Identifiable, Codable {
    let id: UUID
    let time: Date
    let rootFolder: String
    let resolution: String
    let orientation: String
    let aspectRawValue: String        // `AspectRatio.rawValue` - exact, for restore
    let dimensions: String
    let aspectRatio: String           // reduced pixel ratio - display only
    let frameRateValue: Double        // `FrameRate.rawValue` - exact, for restore
    let frameRate: String             // "25 fps" - display only
    let width: Int
    let height: Int
    let leaveFilesInPlace: Bool
    let roleCount: Int
    let collectionCount: Int
    let footageSourceCount: Int

    @MainActor
    init(store: SlateStore, rootFolder: String) {
        id = UUID()
        time = Date()
        self.rootFolder = rootFolder
        resolution = store.choice.rawValue
        orientation = store.choice == .custom ? "-" : store.orientation.rawValue
        aspectRawValue = store.choice == .custom ? "-" : store.aspect.rawValue
        dimensions = store.format.pixelDimensions
        aspectRatio = store.format.aspectRatio
        frameRateValue = store.fcp.frameRate.rawValue
        frameRate = store.fcp.frameRate.label
        width = store.format.width
        height = store.format.height
        leaveFilesInPlace = store.fcp.keepMediaInPlace
        roleCount = store.fcp.videoRoles.count + store.fcp.audioRoles.count
        collectionCount = store.fcp.smartCollections.filter(\.enabled).count
        footageSourceCount = store.footageSources.count
    }
}

@MainActor
@Observable
final class SelectionHistory {
    private(set) var builds: [BuildRecord] = []

    /// `~/Library/Application Support/Slateflow/` - created on first access.
    nonisolated static let directoryURL: URL = {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("Slateflow", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    nonisolated static let fileURL = directoryURL.appendingPathComponent("BuildHistory.json")

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: Self.fileURL),
           let decoded = try? decoder.decode([BuildRecord].self, from: data) {
            builds = decoded
        }
    }

    func record(_ build: BuildRecord) { builds.append(build); persist() }
    func remove(_ build: BuildRecord) { builds.removeAll { $0.id == build.id }; persist() }
    func clear() { builds.removeAll(); persist() }

    /// Merge a previously exported `BuildHistory.json` in - e.g. after a fresh
    /// Mac install. Records already present (matched by id) are skipped, so
    /// importing twice is harmless; nothing existing is ever removed.
    func importBackup(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode([BuildRecord].self, from: Data(contentsOf: url))
        let existingIDs = Set(builds.map(\.id))
        builds.append(contentsOf: imported.filter { !existingIDs.contains($0.id) })
        builds.sort { $0.time < $1.time }
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(builds)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            Log.error("Build Archives save failed: \(error.localizedDescription)")
        }
    }
}
