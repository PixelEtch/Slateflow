//
//  ProjectFolderSection.swift
//  Slateflow
//
//  Template name + the live-computed root folder name.
//

import SwiftUI

struct ProjectFolderSection: View {
    @Bindable var store: SlateStore

    var body: some View {
        Section {
            LabeledContent(Strings.ProjectFolder.templateName) {
                TextField(Strings.ProjectFolder.templateName, text: $store.templateName)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: Spacing.fieldWidth)
            }

            LabeledContent(Strings.ProjectFolder.rootFolder) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: SFSymbol.folderFill).foregroundStyle(Palette.folder)
                    Text(store.rootFolderName).fontDesign(.monospaced)
                }
            }
        } header: {
            Text(Strings.ProjectFolder.section)
        } footer: {
            Text(Strings.ProjectFolder.sequenceNote)
        }
    }
}
