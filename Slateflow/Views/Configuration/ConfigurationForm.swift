//
//  ConfigurationForm.swift
//  Slateflow
//
//  The sidebar form. Each Section is its own component; the grouped Form
//  owns section spacing, so no manual padding here.
//

import SwiftUI

struct ConfigurationForm: View {
    @Bindable var store: SlateStore

    var body: some View {
        Form {
            FormatSection(store: store)
            ProjectFolderSection(store: store)
            FootageSourcesSection(store: store)
            FCPLibrarySection(store: store)

            Section {
                SmartCollectionsSection(store: store)
            } header: {
                Text(Strings.SmartCollections.section)
            } footer: {
                Text(Strings.SmartCollections.footer)
            }
        }
        .formStyle(.grouped)
    }
}
