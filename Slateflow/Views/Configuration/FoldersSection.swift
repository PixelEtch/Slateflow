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
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(store.settings.folders, id: \.self) { path in
                    let name = path.replacingOccurrences(of: "/", with: " › ")
                    HStack {
                        Label(name, systemImage: SFSymbol.folder)
                        Spacer()
                        // The title names the folder, so VoiceOver says what's removed.
                        Button(Strings.Folders.remove(name), systemImage: SFSymbol.remove) {
                            store.settings.removeFolder(path)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                }
                .animation(reduceMotion ? nil : .snappy, value: store.settings.folders.count)

                // Same field + button as Footage Sources.
                HStack(spacing: Spacing.xs) {
                    TextField(Strings.Folders.addLabel, text: $newFolder,
                              prompt: Text(Strings.Folders.addPrompt))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(add)
                    Button(Strings.Folders.add, systemImage: SFSymbol.addCollection, action: add)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .help(Strings.Folders.add)
                        .disabled(newFolder.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } label: {
                Text(summary.isEmpty ? Strings.Folders.none : summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } header: {
            HStack {
                Text(Strings.Folders.section)
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
