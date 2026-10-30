//
//  SettingsForm.swift
//  Slateflow
//
//  The Settings window (⌘,): options set once and rarely changed - the project's
//  folders and the Final Cut setup. Shares the main window's store.
//

import SwiftUI

struct SettingsForm: View {
    @Bindable var store: SlateStore

    var body: some View {
        Form {
            FoldersSection(store: store)

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
                    Toggle(Strings.FCP.leaveFilesInPlace, isOn: $store.settings.fcp.keepMediaInPlace)
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
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.SmartCollections.footer)
                    Text(Strings.FCP.finalCutHints)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: Size.Settings.width, height: Size.Settings.height)
    }
}

#Preview {
    SettingsForm(store: SlateStore())
}
