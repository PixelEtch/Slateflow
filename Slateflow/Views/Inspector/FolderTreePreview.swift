//
//  FolderTreePreview.swift
//  Slateflow
//
//  Live, fully-expanded tree of the folders a build will create.
//

import SwiftUI
import AppKit

struct FolderTreePreview: View {
    let root: DirectoryNode

    var body: some View {
        List {
            Section {
                FolderNodeRow(node: root)
            } footer: {
                Text(Strings.Preview.footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
    }
}

/// Recursive row so the tree renders fully expanded — a preview should hide nothing.
struct FolderNodeRow: View {
    let node: DirectoryNode
    @State private var isExpanded = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let children = node.childNodes {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { FolderNodeRow(node: $0) }
                    .transition(.opacity)
            } label: {
                label
            }
            .animation(reduceMotion ? nil : .snappy, value: children.count)
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: Spacing.xxs) {
            if node.isFile, let systemIcon = node.systemFileIcon {
                Image(nsImage: systemIcon)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: node.previewIcon)
                    .foregroundStyle(node.previewTint)
            }
            Text(node.name)
            if let note = node.note {
                Text(Strings.Preview.note(note))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension DirectoryNode {
    /// View-layer icon for a preview row — folders get the usual folder glyph;
    /// files are told apart by extension, with the FCP library called out in purple.
    var previewIcon: String {
        guard isFile else { return childNodes == nil ? SFSymbol.folder : SFSymbol.folderFill }
        if name.hasSuffix(".fcpbundle") { return "play.rectangle.fill" }
        if name.hasSuffix(".fcpxml") { return "doc.text" }
        return "doc.plaintext"
    }

    var previewTint: Color {
        guard isFile else { return Palette.folder }
        return name.hasSuffix(".fcpbundle") ? .purple : .secondary
    }

    /// The real icon Finder shows for our bundled template library — asked of
    /// Launch Services for that actual file, never shipped as an asset of ours.
    /// (A pure extension→UTType lookup doesn't resolve FCP's icon; FCP registers
    /// it as one of its own document types, which only resolves against a real
    /// file.) `nil` (falling back to `previewIcon`) when no template is bundled.
    var systemFileIcon: NSImage? {
        guard isFile, name.hasSuffix(".fcpbundle"),
              let template = Bundle.main.url(forResource: LibraryTemplate.resourceName,
                                             withExtension: LibraryTemplate.resourceExtension)
        else { return nil }
        return NSWorkspace.shared.icon(forFile: template.path)
    }
}
