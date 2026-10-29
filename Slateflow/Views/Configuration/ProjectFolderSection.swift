//
//  ProjectFolderSection.swift
//  Slateflow
//
//  Project name + the live-computed root folder name.
//

import SwiftUI
import AppKit

struct ProjectFolderSection: View {
    @Bindable var store: SlateStore

    var body: some View {
        Section {
            LabeledContent(Strings.ProjectFolder.templateName) {
                TextField(Strings.ProjectFolder.templateName, text: $store.settings.templateName)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: Size.Field.md)
                    // macOS focuses the first field when the window opens and selects the
                    // name, so one stray key would replace it. Start unfocused; a click edits.
                    .task {
                        // AppKit picks the first responder after the view appears.
                        try? await Task.sleep(for: .milliseconds(100))
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
            }

            LabeledContent(Strings.ProjectFolder.rootFolder) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: SFSymbol.folderFill).foregroundStyle(Palette.folder)
                    Text(store.settings.rootFolderName).fontDesign(.monospaced)
                }
            }
        } header: {
            Text(Strings.ProjectFolder.section)
        } footer: {
            Text(Strings.ProjectFolder.sequenceNote)
        }
    }
}
