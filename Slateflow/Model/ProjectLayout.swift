//
//  ProjectLayout.swift
//  Slateflow
//
//  The on-disk shape of one Slateflow project, and the build that creates it.
//

import Foundation

/// One project is `NNN - <template>/`: the folder tree, `FCP/<root>.fcpxml`, an
/// import note when media stays in place, and `Slate Project.json`. The Folder
/// Preview and the build both come from `plan`, so what's shown is what's written.
nonisolated enum ProjectLayout {
    static let defaultTemplateName = "SlateTemplate"
    static let fcpFolder = "FCP"
    static let importNoteFile = "Import Settings.md"
    static let manifestFile = "Slate Project.json"

    // MARK: Naming

    /// Root folder name, e.g. `001 - SlateTemplate`; past 999 the number just grows.
    static func rootName(sequence: Int, template: String) -> String {
        String(format: "%03d - %@", sequence, template)
    }

    /// Shown before a destination is picked: the number depends on what's already there.
    static func pendingRootName(template: String) -> String { "NNN - \(template)" }

    /// Splits `NNN - name` (three or more digits) into its parts; nil for any other name.
    static func parse(rootName: String) -> (sequence: Int, template: String)? {
        let digits = rootName.prefix { $0.isASCII && $0.isNumber }
        let rest = rootName.dropFirst(digits.count)
        guard digits.count >= 3, let n = Int(digits), rest.hasPrefix(" - ") else { return nil }
        return (n, String(rest.dropFirst(3)))
    }

    /// Next free number given the `NNN - …` folders in `directory`. Starts at 1.
    static func nextSequence(in directory: URL) -> Int {
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return (entries.compactMap { parse(rootName: $0)?.sequence }.max() ?? 0) + 1
    }

    static func fcpxmlURL(root: URL) -> URL {
        root.appendingPathComponent(fcpFolder).appendingPathComponent("\(root.lastPathComponent).fcpxml")
    }

    // MARK: Plan

    /// Every folder and file a build creates under `root`. `Admin` subfolders are
    /// fixed; `Footage` gets one subfolder per source, in order.
    static func plan(root: String, footageSources: [FootageSource],
                     keepMediaInPlace: Bool) -> DirectoryNode {
        var fcpFiles = [DirectoryNode(name: "\(root).fcpxml", isFile: true)]
        if keepMediaInPlace { fcpFiles.append(DirectoryNode(name: importNoteFile, isFile: true)) }

        return DirectoryNode(name: root, children: [
            DirectoryNode(name: "Admin", children: [
                .init(name: "Scripts"), .init(name: "NDAs"), .init(name: "Fonts"), .init(name: "Guidelines"),
            ]),
            DirectoryNode(name: "Audio", children: [
                .init(name: "Dialogue"), .init(name: "Music"), .init(name: "Sound Effects"),
            ]),
            // Point the FCP "Set storage locations" prompt's Backups row here - kept
            // outside FCP/ so it survives a rebuild of the library itself.
            DirectoryNode(name: "Backup", note: "point FCP's library Backups here"),
            DirectoryNode(name: fcpFolder, children: fcpFiles),
            DirectoryNode(name: "Final Exports"),
            DirectoryNode(name: "Footage", children: footageSources.map { DirectoryNode(name: $0.folderName) }),
            DirectoryNode(name: "Graphics"),
            DirectoryNode(name: "Images"),
            DirectoryNode(name: manifestFile, isFile: true),
        ])
    }

    // MARK: Build

    /// Creates the next numbered project in `destination` and returns its URL.
    /// Never merges into an existing folder; on failure, removes the folder it created.
    /// Blocking file I/O: call it off the main actor.
    static func build(_ snapshot: BuildSnapshot, in destination: URL) throws -> URL {
        let root = rootName(sequence: nextSequence(in: destination), template: snapshot.templateName)
        let rootURL = destination.appendingPathComponent(root, isDirectory: true)

        // Backstop: even with the template sanitised, refuse to write outside the chosen folder.
        guard rootURL.isContained(in: destination) else {
            Log.error("Refused build: “\(root)” resolves outside \(destination.path)")
            throw SlateError.destinationEscape(root)
        }
        Log.event("Build started: “\(root)” → \(destination.path)")

        // No intermediate directories: the create itself fails if anything (a folder
        // or a symlink) already has this name, so there's no check-then-create race.
        do {
            try FileManager.default.createDirectory(
                at: rootURL, withIntermediateDirectories: false,
                attributes: [.posixPermissions: FilePermissions.directory])
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            Log.error("Refused build: “\(root)” already exists at the destination")
            throw SlateError.destinationOccupied(root)
        }

        do {
            let tree = plan(root: root, footageSources: snapshot.footageSources,
                            keepMediaInPlace: snapshot.fcp.keepMediaInPlace)
            for child in tree.children { try child.write(into: rootURL) }
            Log.event("Directory tree written (\(snapshot.footageSources.count) footage sources)")

            try snapshot.fcp.write(into: rootURL.appendingPathComponent(fcpFolder),
                                   format: snapshot.format, eventName: root)
            try ProjectManifest(snapshot: snapshot, root: root).write(to: rootURL)
            Log.event("FCPXML, import notes and manifest written; build complete: “\(root)”")
        } catch {
            // Safe to delete: this build created the folder above and it's inside `destination`.
            try? FileManager.default.removeItem(at: rootURL)
            Log.error("Build failed for “\(root)”: \(error.localizedDescription)")
            throw error
        }
        return rootURL
    }
}
