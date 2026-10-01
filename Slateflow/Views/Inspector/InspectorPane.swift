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
    @State private var pane: Pane
    @State private var showClearConfirm = false
    @State private var backupError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether the inspector is showing. SwiftUI keeps an inspector's toolbar items
    /// after it's hidden, so they're only declared while it's shown.
    let isShown: Bool

    init(store: SlateStore, isShown: Bool) {
        _store = Bindable(store)
        self.isShown = isShown
        // Start on Folder Preview until there's a build to show.
        _pane = State(initialValue: store.history.builds.isEmpty ? .preview : .history)
    }

    enum Pane: CaseIterable {
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
                    // Always present: the glass toolbar draws newly inserted items as
                    // empty outlines for a frame, so they're not toggled per pane.
                    // Gap so the archive actions don't read as more tabs of the switch.
                    if #available(macOS 26, *) { ToolbarSpacer(.fixed) }
                    ToolbarItem { clearButton }
                    // Own capsule, so Clear and Backup aren't one grouped control.
                    if #available(macOS 26, *) { ToolbarSpacer(.fixed) }
                    ToolbarItem { backupMenu }
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
                .paneVisible(pane == .history)
            FolderTreePreview(root: DirectoryNode.previewTemplate(
                root: store.rootFolderName, footageSources: store.orderedFootageSources,
                keepMediaInPlace: store.fcp.keepMediaInPlace))
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
            try Data(contentsOf: SelectionHistory.fileURL).write(to: url, options: .atomic)
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

private extension View {
    /// Shown, or hidden but still mounted: invisible, not clickable, skipped by VoiceOver.
    func paneVisible(_ visible: Bool) -> some View {
        opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
    }
}
