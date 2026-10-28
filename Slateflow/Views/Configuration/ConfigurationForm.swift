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
                // Same shape as a collection row: text, then a centred switch.
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(Strings.FCP.leaveFilesInPlace)
                        Text(Strings.FCP.leaveFilesInPlaceHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(Strings.FCP.leaveFilesInPlace, isOn: $store.fcp.keepMediaInPlace)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    // Same trailing space as a collection's remove button, so the
                    // switches below line up with this one.
                    Image(systemName: SFSymbol.remove).hidden()
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
