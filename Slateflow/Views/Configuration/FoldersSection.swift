//
//  FoldersSection.swift
//  Slateflow
//
//  The editable folders of the Project Layout: remove, add by path, restore defaults.
//

import SwiftUI

struct FoldersSection: View {
    @Bindable var store: SlateStore
    @State private var newFolder = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section {
            ForEach(store.settings.folders, id: \.self) { path in
                HStack {
                    Label(path.replacingOccurrences(of: "/", with: " › "), systemImage: SFSymbol.folder)
                    Spacer()
                    Button(Strings.Folders.remove, systemImage: SFSymbol.remove) {
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
        } header: {
            HStack {
                Text(Strings.Folders.section)
                Spacer()
                Button(Strings.Folders.reset) { store.settings.resetFolders() }
                    .buttonStyle(.link)
                    .font(.callout)
                    .disabled(store.settings.folders == ProjectLayout.defaultFolders)
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
