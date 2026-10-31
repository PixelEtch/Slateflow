//
//  FoldersSection.swift
//  Slateflow
//
//  The editable folders of the Project Layout: remove, add by path, restore defaults.
//  Collapsed to a one-line summary by default - they're set once and rarely changed.
//

import SwiftUI

struct FoldersSection: View {
    @Bindable var store: SlateStore
    @State private var newFolder = ""
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Top-level folder names, e.g. "Admin, Audio, Final Exports, Graphics, Images".
    private var summary: String {
        var seen = Set<String>()
        return store.settings.folders
            .compactMap { $0.split(separator: "/").first.map(String.init) }
            .filter { seen.insert($0).inserted }
            .joined(separator: ", ")
    }

    var body: some View {
        Section {
            ExpandableRow(isExpanded: $isExpanded) {
                Text(summary.isEmpty ? Strings.Folders.none : summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            } content: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(store.settings.folders, id: \.self) { path in
                        let name = path.replacingOccurrences(of: "/", with: " › ")
                        HStack {
                            Label(name, systemImage: SFSymbol.folder)
                            Spacer()
                            RemoveButton(title: Strings.Folders.remove(name)) {
                                store.settings.removeFolder(path)
                            }
                        }
                    }
                    .animation(reduceMotion ? nil : .snappy, value: store.settings.folders.count)

                    AddField(label: Strings.Folders.addLabel, prompt: Strings.Folders.addPrompt,
                             addTitle: Strings.Folders.add, text: $newFolder, onAdd: add)
                }
                .padding(.top, Spacing.sm)
            }
        } header: {
            // No title: the Folders tab above already names it.
            HStack {
                Spacer()
                // Only offered when there's something to restore.
                if store.settings.folders != ProjectLayout.defaultFolders {
                    Button(Strings.Folders.reset) { store.settings.resetFolders() }
                        .buttonStyle(.link)
                        .font(.callout)
                }
            }
        } footer: {
            Text(Strings.Folders.footer)
        }
    }

    private func add() {
        store.settings.addFolder(newFolder)
        newFolder = ""
    }
}
