//
//  FolderTreePreview.swift
//  Slateflow
//
//  Live, fully-expanded tree of the folders a build will create.
//

import SwiftUI

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

/// Recursive row so the tree renders fully expanded - a preview should hide nothing.
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
            Image(systemName: node.previewIcon)
                .foregroundStyle(node.previewTint)
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
    /// View-layer icon for a preview row - folders get the usual folder glyph;
    /// files are told apart by extension.
    var previewIcon: String {
        guard isFile else { return childNodes == nil ? SFSymbol.folder : SFSymbol.folderFill }
        if name.hasSuffix(".fcpxml") { return SFSymbol.fcpxmlFile }
        return SFSymbol.textFile
    }

    var previewTint: Color {
        guard isFile else { return Palette.folder }
        return .secondary
    }
}
