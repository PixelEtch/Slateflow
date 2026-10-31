//
//  InspectorPane.swift
//  Slateflow
//
//  Trailing inspector: pinned pane switcher over History or Folder Preview.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct InspectorPane: View {
    @Bindable var store: SlateStore
    @SceneStorage("inspectorPane") private var pane: Pane = .preview
    @State private var showClearConfirm = false
    @State private var backupError: String?
    @State private var hoveringAction = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether the inspector is showing. SwiftUI keeps an inspector's toolbar items
    /// after it's hidden, so they're only declared while it's shown.
    let isShown: Bool

    init(store: SlateStore, isShown: Bool) {
        _store = Bindable(store)
        self.isShown = isShown
        // Remembered per window; first launch starts on Folder Preview until there's
        // a build to show.
        _pane = SceneStorage(wrappedValue: store.history.builds.isEmpty ? .preview : .history,
                             "inspectorPane")
    }

    enum Pane: String, CaseIterable {
        case history, preview
        var title: String {
            switch self {
            case .history: Strings.Inspector.archives
            case .preview: Strings.Inspector.preview
            }
        }
        var symbol: String {
            switch self {
            case .history: SFSymbol.historyEmpty
            case .preview: SFSymbol.folder
            }
        }
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // In the window toolbar above the inspector, so the system draws them
            // (Liquid Glass on macOS 26) instead of a custom bar.
            .toolbar {
                if isShown {
                    ToolbarItem {
                        Picker(Strings.Inspector.viewPicker, selection: $pane) {
                            ForEach(Pane.allCases, id: \.self) { Label($0.title, systemImage: $0.symbol).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelStyle(.titleAndIcon)
                        .labelsHidden()
                    }
                    // Xcode-style tray: Clear and Backup in one capsule (like Run / Stop),
                    // set apart from the switch, shown only on Build Archives. Toolbar
                    // items themselves never change - inserting, removing or hiding glass
                    // items flashes empty outlines - so the tray fades its own content.
                    if #available(macOS 26, *) {
                        ToolbarSpacer(.fixed)
                        ToolbarItem {
                            // Own glass capsule instead of the toolbar's, so it can fade.
                            archiveTray
                                .padding(.horizontal, Spacing.xxs)
                                .glassEffect(.regular, in: .capsule)
                                .paneVisible(pane == .history)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem { archiveTray.paneVisible(pane == .history) }
                    }
                }
            }
            .confirmationDialog(Strings.Inspector.clearConfirmTitle(count: store.history.builds.count),
                               isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button(Strings.Inspector.clearConfirmAction, role: .destructive) {
                    store.history.clear()
                }
            } message: {
                Text(Strings.Inspector.clearConfirmMessage)
            }
            .alert(Strings.Inspector.backupErrorTitle,
                   isPresented: Binding(get: { backupError != nil },
                                        set: { if !$0 { backupError = nil } })) {
                Button(Strings.Build.ok, role: .cancel) {}
            } message: {
                Text(backupError ?? "")
            }
    }

    /// Clear | Backup with a firm 1 pt rule between (Divider is too faint). The rule
    /// hides while either button is hovered, as in Xcode's tray.
    private var archiveTray: some View {
        HStack(spacing: 0) {
            clearButton
            Rectangle()
                .fill(.secondary)
                .frame(width: 1, height: Size.Icon.md)
                .padding(.horizontal, Spacing.xxxs)
                .opacity(hoveringAction ? 0 : 1)
            backupMenu
        }
        .onHover { hoveringAction = $0 }
    }

    private var clearButton: some View {
        Button(Strings.Inspector.clearHistory, systemImage: SFSymbol.clearHistory) {
            showClearConfirm = true
        }
        .foregroundStyle(Palette.destructive)
        .help(Strings.Inspector.clearHistory)
        .disabled(store.history.builds.isEmpty)
    }

    private var backupMenu: some View {
        Menu {
            Button(Strings.Inspector.exportBackup) { exportBackup() }
                .disabled(store.history.builds.isEmpty)
            Button(Strings.Inspector.importBackup) { importBackup() }
        } label: {
            Label(Strings.Inspector.backupMenu, systemImage: SFSymbol.backup)
        }
        .help(Strings.Inspector.backupMenu)
        .menuIndicator(.hidden)
    }

    /// Both panes stay mounted and cross-fade, so switching keeps each pane's scroll
    /// position and doesn't rebuild the list or tree.
    private var content: some View {
        ZStack {
            HistoryList(store: store)
                // Fill the pane even when empty, so the note sits at the bottom, not under the message.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    // Pinned under the list, so it stays visible however long it gets.
                    BarNote(text: Strings.History.storageNote, alignment: .leading)
                }
                .paneVisible(pane == .history)
            FolderTreePreview(root: ProjectLayout.plan(
                root: store.settings.rootFolderName, folders: store.settings.folders, footageSources: store.settings.orderedFootageSources))
                .paneVisible(pane == .preview)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: pane)
    }

    /// Save a copy of the build archive - e.g. before wiping or reinstalling macOS.
    private func exportBackup() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Slateflow Build History.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.history.exportBackup(to: url)
        } catch {
            backupError = error.localizedDescription
        }
    }

    /// Restore a previously exported archive - records already present are skipped,
    /// nothing existing is ever removed.
    private func importBackup() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.history.importBackup(from: url)
        } catch {
            backupError = error.localizedDescription
        }
    }
}

extension View {
    /// Shown, or hidden but still mounted: invisible, not clickable, skipped by VoiceOver.
    /// Used for panes and tabs that switch by fading, so they keep their state.
    func paneVisible(_ visible: Bool) -> some View {
        opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
    }
}
