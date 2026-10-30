//
//  SettingsForm.swift
//  Slateflow
//
//  The Customize Projects window (⌘,): options set once and rarely changed - the project’s
//  folders and the Final Cut setup. Shares the main window's store.
//

import SwiftUI

/// The Settings tab, remembered so Customize… and the Edit links open the right one.
enum SettingsTab: String {
    case folders, smartCollections
    static let storageKey = "settingsTab"
    static let windowID = "customize"
}

struct SettingsForm: View {
    @Bindable var store: SlateStore
    @AppStorage(SettingsTab.storageKey) private var tab = SettingsTab.folders

    var body: some View {
        VStack(spacing: 0) {
            tabSwitch
                .padding(.top, Spacing.md)
            switch tab {
            case .folders:
                Form { FoldersSection(store: store) }
                    .formStyle(.grouped)
            case .smartCollections:
                smartCollections
            }
        }
        // No Save button, as in macOS Settings: every change is stored as it's made.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // A bar, like the main window's bottom bar, so the list scrolls under it.
            VStack(spacing: 0) {
                Divider()
                Text(Strings.Settings.autosave)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(.bar)
            }
        }
        .frame(width: Size.Settings.width, height: Size.Settings.height)
    }

    /// Same size and Liquid Glass capsule as the main window's Recent Projects / Folder
    /// Preview switch.
    @ViewBuilder private var tabSwitch: some View {
        let picker = Picker(Strings.Settings.tabs, selection: $tab) {
            Text(Strings.Folders.section).tag(SettingsTab.folders)
            Text(Strings.SmartCollections.section).tag(SettingsTab.smartCollections)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.large)
        .fixedSize()
        // Grey selection like the toolbar switch, not the accent blue a content picker gets.
        .tint(Color(nsColor: .tertiaryLabelColor))
        if #available(macOS 26, *) {
            picker
                .padding(Spacing.xxxs)
                .glassEffect(.regular, in: .capsule)
        } else {
            picker
        }
    }

    private var smartCollections: some View {
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
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(title) {
            settingsTab = tab
            openWindow(id: SettingsTab.windowID)
        }
    }
}

/// Slateflow ▸ Customize Projects… (⌘,), in place of the standard Settings… item.
struct CustomizeProjectsCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(Strings.Settings.menuItem) { openWindow(id: SettingsTab.windowID) }
            .keyboardShortcut(",", modifiers: .command)
    }
}

#Preview {
    SettingsForm(store: SlateStore())
}
