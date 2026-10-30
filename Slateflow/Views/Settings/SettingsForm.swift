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
        // Icon tabs as in Xcode's inspectors: the window keeps its "Slateflow Settings" title.
        VStack(spacing: 0) {
            Picker(Strings.Settings.tabs, selection: $tab) {
                tabIcon(Strings.Folders.section, SFSymbol.folder).tag(SettingsTab.folders)
                tabIcon(Strings.FCP.section, SFSymbol.finalCut).tag(SettingsTab.finalCut)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.top, Spacing.md)

            switch tab {
            case .folders:
                Form { FoldersSection(store: store) }
                    .formStyle(.grouped)
            case .finalCut:
                finalCut
            }
        }
        .frame(width: Size.Settings.width, height: Size.Settings.height)
    }

    private func tabIcon(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .labelStyle(.iconOnly)
            .help(title)
    }

    private var finalCut: some View {
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
