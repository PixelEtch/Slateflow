//
//  ProjectFolderSection.swift
//  Slateflow
//
//  Project name; its tooltip explains the number added in front.
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
                    .help(Strings.ProjectFolder.sequenceNote)
                    // Return ends editing. Async: AppKit is still inside the field's submit.
                    .onSubmit { DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) } }
            }
        } header: {
            Text(Strings.ProjectFolder.section)
        }
    }
}
