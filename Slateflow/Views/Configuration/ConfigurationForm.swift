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
            ProjectFolderSection(store: store)
            FormatSection(store: store)
            FootageSourcesSection(store: store)

            Section {
                Toggle(isOn: $store.fcp.keepMediaInPlace) {
                    Text(Strings.FCP.leaveFilesInPlace)
                    Text(Strings.FCP.leaveFilesInPlaceHelp)
                }
                SmartCollectionsSection(store: store)
            } header: {
                Text(Strings.FCP.section)
            } footer: {
                Text(Strings.SmartCollections.footer)
            }
        }
        .formStyle(.grouped)
    }
}
