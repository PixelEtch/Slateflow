//
//  ProjectFolderSection.swift
//  Slateflow
//
//  Project name + the live-computed root folder name.
//

import SwiftUI

struct ProjectFolderSection: View {
    @Bindable var store: SlateStore

    var body: some View {
        Section {
            LabeledContent(Strings.ProjectFolder.templateName) {
                TextField(Strings.ProjectFolder.templateName, text: $store.settings.templateName)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: Size.Field.md)
                    // Return ends editing. Async: AppKit is still inside the field's submit.
                    .onSubmit { DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) } }
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
