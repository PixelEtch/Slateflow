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

    init(store: SlateStore) {
        _store = Bindable(store)
        // Start on Folder Preview until there's a build to show.
        _pane = State(initialValue: store.history.builds.isEmpty ? .preview : .history)
    }

    enum Pane: CaseIterable, Identifiable {
        case history, preview
        var id: Self { self }
        var title: String {
            switch self {
            case .history: Strings.Inspector.archives
            case .preview: Strings.Inspector.preview
            }
        }
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) { header }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if pane == .history, !store.history.builds.isEmpty {
                    footer
                }
            }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            Text(Strings.History.storageNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
        }
        .background(.bar)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.xs) {
                Picker(Strings.Inspector.viewPicker, selection: $pane) {
                    ForEach(Pane.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()

                Spacer(minLength: Spacing.sm)

                if pane == .history {
                    HStack(spacing: Spacing.sm) { historyActionButtons }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            Divider()
        }
        .background(.bar)
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

    @ViewBuilder private var historyActionButtons: some View {
        Button(Strings.Inspector.clearHistory, systemImage: SFSymbol.clearHistory) {
            showClearConfirm = true
        }
        .disabled(store.history.builds.isEmpty)

        Menu {
            Button(Strings.Inspector.exportBackup) { exportBackup() }
                .disabled(store.history.builds.isEmpty)
            Button(Strings.Inspector.importBackup) { importBackup() }
        } label: {
            Label(Strings.Inspector.backupMenu, systemImage: SFSymbol.backup)
        }
        .menuIndicator(.hidden)
    }

    @ViewBuilder private var content: some View {
        switch pane {
        case .history:
            HistoryList(store: store)
        case .preview:
            FolderTreePreview(root: DirectoryNode.previewTemplate(
                root: store.rootFolderName, footageSources: store.orderedFootageSources,
                keepMediaInPlace: store.fcp.keepMediaInPlace))
        }
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
