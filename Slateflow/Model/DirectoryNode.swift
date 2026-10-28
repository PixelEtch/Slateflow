//
//  DirectoryNode.swift
//  Slateflow
//
//  A folder tree: written to disk by a build, shown in the Folder Preview.
//

import Foundation

struct DirectoryNode: Identifiable {
    var name: String
    var children: [DirectoryNode] = []
    var note: String? = nil            // shown in the Folder Preview only
    var isFile: Bool = false           // written by its owner (FCPXML, manifest), not by write()

    // shortcut: names are unique within this template tree; use a path id if names can repeat.
    var id: String { name }

    /// `nil` for leaves - the shape `OutlineGroup(_:children:)` expects.
    var childNodes: [DirectoryNode]? { children.isEmpty ? nil : children }

    /// Recursively create this folder and every descendant folder under `parent`;
    /// file nodes are skipped. `name` is expected to be pre-sanitised; the `SafeName`
    /// pass here is defense in depth.
    nonisolated func write(into parent: URL) throws {
        guard !isFile else { return }
        let dir = parent.appendingPathComponent(SafeName.component(name, fallback: "Folder"),
                                                isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        for child in children { try child.write(into: dir) }
    }

    /// Flat relative paths - pure, for previews and checks.
    nonisolated func paths(prefix: String = "") -> [String] {
        let here = prefix.isEmpty ? name : "\(prefix)/\(name)"
        return [here] + children.flatMap { $0.paths(prefix: here) }
    }
}
