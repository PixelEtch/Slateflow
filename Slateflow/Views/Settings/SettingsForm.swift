//
//  SettingsForm.swift
//  Slateflow
//
//  The Settings window (⌘,): options set once and rarely changed - the project's
//  folders and the Final Cut setup. Shares the main window's store.
//

import SwiftUI

/// The Settings tab, remembered so Customize… and the Edit links open the right one.
enum SettingsTab: String {
    case folders, finalCut
    static let storageKey = "settingsTab"
}

struct SettingsForm: View {
    @Bindable var store: SlateStore
    @AppStorage(SettingsTab.storageKey) private var tab = SettingsTab.folders

    var body: some View {
        TabView(selection: $tab) {
            Form { FoldersSection(store: store) }
                .formStyle(.grouped)
                .tabItem { Label(Strings.Folders.section, systemImage: SFSymbol.folder) }
                .tag(SettingsTab.folders)

            Form {
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
                    Text(Strings.SmartCollections.section)
                } footer: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(Strings.SmartCollections.footer)
                        Text(Strings.FCP.finalCutHints)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label(Strings.FCP.section, systemImage: SFSymbol.finalCut) }
            .tag(SettingsTab.finalCut)
        }
        .frame(width: Size.Settings.width, height: Size.Settings.height)
    }
}

/// Opens Settings on `tab` - for links to options that live there.
struct SettingsButton: View {
    let title: String
    let tab: SettingsTab
    @AppStorage(SettingsTab.storageKey) private var settingsTab = SettingsTab.folders
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(title) {
            settingsTab = tab
            openSettings()
        }
    }
}

#Preview {
    SettingsForm(store: SlateStore())
}
