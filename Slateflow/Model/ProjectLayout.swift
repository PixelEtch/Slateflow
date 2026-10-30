//
//  ProjectLayout.swift
//  Slateflow
//
//  The on-disk shape of one Slateflow project, and the build that creates it.
//

import Foundation

/// One project is `NNN - <template>/`: the folder tree, `FCP/<root>.fcpxml`, and the
/// hidden manifest `.slateflow.json`. The Folder
/// Preview and the build both come from `plan`, so what's shown is what's written.
nonisolated enum ProjectLayout {
    static let defaultTemplateName = "SlateTemplate"
    static let fcpFolder = "FCP"
    /// Hidden (a dot-file), so the Project shows only folders the editor uses.
    static let manifestFile = ".slateflow.json"
    static let backupFolder = "Backup"
    static let footageFolder = "Footage"

    /// The folders users can change in the Folders section, as `/`-separated paths.
    /// `Backup`, `FCP` and `Footage` are always created and can't be edited.
    static let defaultFolders = [
        "Admin/Scripts", "Admin/NDAs", "Admin/Fonts", "Admin/Guidelines",
        "Audio/Dialogue", "Audio/Music", "Audio/Sound Effects",
        "Final Exports", "Graphics", "Images",
    ]

    /// `path` split into safe path components (each sanitised, blanks dropped); nil when
    /// nothing is left or it would land in or replace a folder or file Slateflow owns.
    static func folderComponents(_ path: String) -> [String]? {
        let parts = path.split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { SafeName.component($0, fallback: "") }
            .filter { !$0.isEmpty }
        let owned = [backupFolder, fcpFolder, footageFolder, manifestFile]
        guard let top = parts.first,
              !owned.contains(where: { $0.caseInsensitiveCompare(top) == .orderedSame })
        else { return nil }
        return parts
    }

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

    /// Every folder and file a build creates under `root`: the user's `folders`, plus
    /// `Backup`, `FCP` and `Footage` (one subfolder per source, in order). Top-level
    /// folders are sorted by name; subfolders keep the order they were added in.
    static func plan(root: String, folders: [String], footageSources: [FootageSource]) -> DirectoryNode {
        var top = [
            // Point the FCP "Set storage locations" prompt's Backups row here - kept
            // outside FCP/ so it survives a rebuild of the library itself.
            DirectoryNode(name: backupFolder, note: "point FCP's library Backups here"),
            DirectoryNode(name: fcpFolder, children: [DirectoryNode(name: "\(root).fcpxml", isFile: true)]),
            DirectoryNode(name: footageFolder, children: footageSources.map { DirectoryNode(name: $0.folderName) }),
        ]
        for path in folders {
            if let parts = folderComponents(path) { insert(parts[...], into: &top) }
        }
        top.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let manifest = DirectoryNode(name: manifestFile, note: "hidden in Finder", isFile: true)
        return DirectoryNode(name: root, children: top + [manifest])
            .withPathIDs()
    }

    /// Adds the folder path to `nodes`, reusing a folder of the same name (any case).
    private static func insert(_ parts: ArraySlice<String>, into nodes: inout [DirectoryNode]) {
        guard let first = parts.first else { return }
        if let i = nodes.firstIndex(where: { $0.name.caseInsensitiveCompare(first) == .orderedSame }) {
            insert(parts.dropFirst(), into: &nodes[i].children)
        } else {
            var node = DirectoryNode(name: first)
            insert(parts.dropFirst(), into: &node.children)
            nodes.append(node)
        }
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
                at: rootURL, withIntermediateDirectories: false)
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            Log.error("Refused build: “\(root)” already exists at the destination")
            throw SlateError.destinationOccupied(root)
        }

        do {
            let tree = plan(root: root, folders: snapshot.folders, footageSources: snapshot.footageSources)
            for child in tree.children { try child.write(into: rootURL) }
            Log.event("Directory tree written (\(snapshot.footageSources.count) footage sources)")

            try snapshot.fcp.write(into: rootURL.appendingPathComponent(fcpFolder),
                                   format: snapshot.format, reelFormat: snapshot.reelFormat, eventName: root)
            try ProjectManifest(snapshot: snapshot, root: root).write(to: rootURL)
            Log.event("FCPXML and manifest written; build complete: “\(root)”")
        } catch {
            // Safe to delete: this build created the folder above and it's inside `destination`.
            try? FileManager.default.removeItem(at: rootURL)
            Log.error("Build failed for “\(root)”: \(error.localizedDescription)")
            throw error
        }
        return rootURL
    }
}
