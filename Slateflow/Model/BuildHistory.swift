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
    let frameRateValue: Double        // `FrameRate.rawValue` - exact, for restore
    let width: Int
    let height: Int
    let leaveFilesInPlace: Bool
    let roleCount: Int
    let collectionCount: Int
    let footageSourceCount: Int

    init(snapshot s: BuildSnapshot, rootFolder: String) {
        id = UUID()
        time = Date()
        self.rootFolder = rootFolder
        resolution = s.choice.rawValue
        orientation = s.orientationLabel
        aspectRawValue = s.choice == .custom ? "-" : s.aspect.rawValue
        frameRateValue = s.fcp.frameRate.rawValue
        width = s.format.width
        height = s.format.height
        leaveFilesInPlace = s.fcp.keepMediaInPlace
        roleCount = s.fcp.videoRoles.count + s.fcp.audioRoles.count
        collectionCount = s.fcp.smartCollections.filter(\.enabled).count
        footageSourceCount = s.footageSources.count
    }

    // Display values, derived from the stored raw values. Older archives also stored
    // these as strings; decoding ignores the extra keys.
    var dimensions: String { VideoFormat(width: width, height: height).pixelDimensions }
    var aspectRatio: String { VideoFormat(width: width, height: height).aspectRatio }
    var frameRate: String { FrameRate(rawValue: frameRateValue)?.label ?? "\(frameRateValue) fps" }
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

    nonisolated static let defaultFileURL = directoryURL.appendingPathComponent("BuildHistory.json")

    /// Where this archive lives: Application Support in the app, a temp file in the self-check.
    @ObservationIgnored let fileURL: URL

    init(fileURL: URL = SelectionHistory.defaultFileURL) {
        self.fileURL = fileURL
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL),
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

    /// Write every record to `url` in the same format `importBackup` reads.
    func exportBackup(to url: URL) throws {
        try Self.encoded(builds).write(to: url, options: .atomic)
    }

    private func persist() {
        do {
            try Self.encoded(builds).write(to: fileURL, options: .atomic)
        } catch {
            Log.error("Build Archives save failed: \(error.localizedDescription)")
        }
    }

    private static func encoded(_ builds: [BuildRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(builds)
    }
}
