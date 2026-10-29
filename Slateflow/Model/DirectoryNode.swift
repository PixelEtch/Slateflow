//
//  DirectoryNode.swift
//  Slateflow
//
//  A folder tree: written to disk by a build, shown in the Folder Preview.
//

import Foundation

struct DirectoryNode: Identifiable {
    var name: String
    var children: [DirectoryNode]
    var note: String?                  // shown in the Folder Preview only
    var isFile: Bool                   // written by its owner (FCPXML, manifest), not by write()
    /// The name until `withPathIDs()` sets the path from the root: user folders can
    /// repeat a name under different parents (Audio/Music, Graphics/Music).
    var id: String

    nonisolated init(name: String, children: [DirectoryNode] = [], note: String? = nil, isFile: Bool = false) {
        self.name = name
        self.children = children
        self.note = note
        self.isFile = isFile
        id = name
    }

    /// This tree with every `id` set to the node's path, so ids are unique.
    nonisolated func withPathIDs(prefix: String = "") -> DirectoryNode {
        var node = self
        node.id = prefix.isEmpty ? name : "\(prefix)/\(name)"
        node.children = children.map { $0.withPathIDs(prefix: node.id) }
        return node
    }

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
