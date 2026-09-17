//
//  ContentView.swift
//  Slateflow
//
//  Root scene: configuration form + bottom build bar + trailing inspector.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var store = SlateStore()
    @State private var buildError: String?
    @State private var builtProject: URL?
    @State private var isBuilding = false
    @State private var showInspector = true

    var body: some View {
        ConfigurationForm(store: store)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BuildBar(rootFolderName: store.rootFolderName,
                         isBuilding: isBuilding,
                         action: chooseAndBuild)
            }
            .inspector(isPresented: $showInspector) {
                InspectorPane(store: store)
                    .inspectorColumnWidth(min: 300, ideal: 350, max: 460)
            }
            .focusedSceneValue(\.buildAction, chooseAndBuild)
            .toolbar {
                ToolbarItem {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Label(Strings.App.inspector, systemImage: SFSymbol.inspector)
                    }
                    .help(Strings.App.inspectorToggleHelp)
                }
            }
            .frame(minWidth: 640, minHeight: 520)
            .alert(Strings.Build.errorTitle,
                   isPresented: Binding(get: { buildError != nil },
                                        set: { if !$0 { buildError = nil } })) {
                Button(Strings.Build.chooseAnother) { chooseAndBuild() }
                Button(Strings.Build.ok, role: .cancel) {}
            } message: {
                Text(buildError ?? "")
            }
            .alert(Strings.Build.successTitle,
                   isPresented: Binding(get: { builtProject != nil },
                                        set: { if !$0 { builtProject = nil } })) {
                Button(Strings.Build.openInFCP) {
                    if let builtProject { openInFinalCut(fcpOpenTarget(for: builtProject)) }
                }
                Button(Strings.Build.reveal) {
                    if let builtProject {
                        NSWorkspace.shared.activateFileViewerSelecting([builtProject])
                    }
                }
                Button(Strings.Build.done, role: .cancel) {}
            } message: {
                Text(Strings.Build.successMessage(rootFolder: builtProject?.lastPathComponent ?? ""))
            }
    }

    private func chooseAndBuild() {
        guard !isBuilding else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = Strings.Build.panelPrompt
        panel.message = Strings.Build.panelMessage(rootFolder: store.rootFolderName)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        isBuilding = true
        Task {
            // NSOpenPanel already grants sandbox access to `url` for this session; the
            // build writes immediately, so no persistent bookmark is needed. Bracket the
            // write in a scoped-access pair for correctness if `url` ever comes from a bookmark.
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            do { builtProject = try await store.buildProject(at: url) }
            catch { buildError = error.localizedDescription }
            isBuilding = false
        }
    }

    /// `<root>/FCP/<root>.fcpxml` — matches the name `FCPLibrarySettings.write` gives it.
    private func fcpxmlURL(for root: URL) -> URL {
        root.appendingPathComponent("FCP").appendingPathComponent("\(root.lastPathComponent).fcpxml")
    }

    /// `<root>/FCP/<root>.fcpbundle` — matches the name `LibraryTemplate.copy` gives it.
    private func fcpbundleURL(for root: URL) -> URL {
        root.appendingPathComponent("FCP")
            .appendingPathComponent("\(root.lastPathComponent).\(LibraryTemplate.resourceExtension)")
    }

    /// Prefer opening the pre-made library (skips FCP's "Open Library" dialog entirely)
    /// when one was created; otherwise fall back to the fcpxml.
    private func fcpOpenTarget(for root: URL) -> URL {
        let bundle = fcpbundleURL(for: root)
        return FileManager.default.fileExists(atPath: bundle.path) ? bundle : fcpxmlURL(for: root)
    }

    /// `NSWorkspace.open(_:)` (the plain Bool-returning overload) doesn't reliably
    /// bring an already-running app forward. Request activation explicitly.
    private func openInFinalCut(_ url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        Task { try? await NSWorkspace.shared.open(url, configuration: config) }
    }
}

/// The primary action, pinned below the form in a native macOS bottom bar.
struct BuildBar: View {
    let rootFolderName: String
    let isBuilding: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Spacing.md) {
                Label(rootFolderName, systemImage: SFSymbol.folderFill)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: Spacing.md)
                if isBuilding {
                    ProgressView().controlSize(.small)
                }
                Button(Strings.Build.button, systemImage: SFSymbol.build, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isBuilding)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.bar)
        }
    }
}

// MARK: - Menu-bar wiring

/// Lets the `Build Project…` menu command trigger the same flow as the bottom bar.
struct BuildActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var buildAction: (() -> Void)? {
        get { self[BuildActionKey.self] }
        set { self[BuildActionKey.self] = newValue }
    }
}

struct BuildCommand: View {
    @FocusedValue(\.buildAction) private var buildAction

    var body: some View {
        Button(Strings.Build.menuItem) { buildAction?() }
            .keyboardShortcut("b", modifiers: .command)
            .disabled(buildAction == nil)
    }
}

#Preview {
    ContentView()
}
