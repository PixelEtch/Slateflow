//
//  DirectoryNode.swift
//  Slateflow
//
//  The Slate project folder hierarchy - real writer + a display-only preview.
//

import Foundation

struct DirectoryNode: Identifiable {
    var name: String
    var children: [DirectoryNode] = []
    var note: String? = nil            // shown in the Folder Preview only
    var isFile: Bool = false           // preview-only - write() only ever creates directories

    // ponytail: names are unique across this template tree; use a path id if that changes.
    var id: String { name }

    /// `nil` for leaves - the shape `OutlineGroup(_:children:)` expects.
    var childNodes: [DirectoryNode]? { children.isEmpty ? nil : children }

    /// Slate hierarchy rooted at `root` (`001 - SlateTemplate`).
    /// `Admin` subfolders are fixed; `Footage` subfolders are one per entry in
    /// `footageSources`, in the given order; an empty list leaves `Footage` a leaf.
    nonisolated static func slateTemplate(root: String,
                                          footageSources: [FootageSource] = []) -> DirectoryNode {
        let footageChildren = footageSources.map { DirectoryNode(name: $0.folderName) }

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
            DirectoryNode(name: "FCP", note: "generated .fcpxml / library - point Media/Cache here"),
            DirectoryNode(name: "Final Exports"),
            DirectoryNode(name: "Footage", children: footageChildren),
            DirectoryNode(name: "Graphics"),
            DirectoryNode(name: "Images"),
        ])
    }

    /// `slateTemplate` with `FCP/`'s actual contents spelled out for display - the
    /// fcpxml and the import note (if media is left in place). Preview-only: never fed to `write()`, so this can't
    /// affect what a real build creates.
    nonisolated static func previewTemplate(root: String, footageSources: [FootageSource] = [],
                                             keepMediaInPlace: Bool = true) -> DirectoryNode {
        var tree = slateTemplate(root: root, footageSources: footageSources)
        guard let fcpIndex = tree.children.firstIndex(where: { $0.name == "FCP" }) else { return tree }

        var fcpChildren = [DirectoryNode(name: "\(root).fcpxml", isFile: true)]
        if keepMediaInPlace {
            fcpChildren.append(DirectoryNode(name: "Import Settings.md", isFile: true))
        }
        tree.children[fcpIndex].children = fcpChildren
        tree.children[fcpIndex].note = nil
        return tree
    }

    /// Recursively create this folder and every descendant under `parent`.
    /// `name` is expected to be pre-sanitised; the `SafeName` pass here is defense in depth.
    nonisolated func write(into parent: URL) throws {
        let dir = parent.appendingPathComponent(SafeName.component(name, fallback: "Folder"),
                                                isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.directory])
        for child in children { try child.write(into: dir) }
    }

    /// Flat relative paths - pure, for previews and checks.
    nonisolated func paths(prefix: String = "") -> [String] {
        let here = prefix.isEmpty ? name : "\(prefix)/\(name)"
        return [here] + children.flatMap { $0.paths(prefix: here) }
    }
}
