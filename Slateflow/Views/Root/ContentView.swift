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
    @SceneStorage("showInspector") private var showInspector = true
    /// Set once the window's launch focus has been cleared - see `clearLaunchFocus`.
    @State private var launchFocusCleared = false

    var body: some View {
        ConfigurationForm(store: store)
            .frame(minWidth: Size.Window.formMinWidth)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BuildBar(rootFolderName: store.settings.rootFolderName,
                         destination: store.destination,
                         isBuilding: isBuilding,
                         build: build,
                         change: { _ = chooseDestination() })
            }
            .inspector(isPresented: $showInspector) {
                InspectorPane(store: store, isShown: showInspector)
                    .inspectorColumnWidth(min: Size.Inspector.min, ideal: Size.Inspector.ideal, max: Size.Inspector.max)
            }
            .focusedSceneValue(\.buildAction, build)
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
            .frame(minHeight: Size.Window.minHeight)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification),
                       perform: clearLaunchFocus)
            .alert(Strings.Build.errorTitle,
                   isPresented: Binding(get: { buildError != nil },
                                        set: { if !$0 { buildError = nil } })) {
                Button(Strings.Build.chooseAnother) { chooseAndBuild() }
                Button(Strings.Build.ok, role: .cancel) {}
            } message: {
                Text(buildError ?? "")
            }
            .sheet(isPresented: Binding(get: { builtProject != nil },
                                        set: { if !$0 { builtProject = nil } })) {
                if let builtProject {
                    BuildSuccessSheet(
                        rootFolder: builtProject.lastPathComponent,
                        keepMediaInPlace: store.settings.fcp.keepMediaInPlace,
                        onOpen: { await FinalCutLibrary.open(project: builtProject) },
                        onReveal: { NSWorkspace.shared.activateFileViewerSelecting([builtProject]) })
                }
            }
    }

    /// AppKit focuses the first text field the first time the window becomes key and
    /// selects the project name, so one stray key would replace it. Clear that once; a
    /// click or Tab still edits. Waits a turn so it runs after AppKit sets the focus.
    private func clearLaunchFocus(_ note: Notification) {
        guard !launchFocusCleared, let window = note.object as? NSWindow else { return }
        launchFocusCleared = true
        DispatchQueue.main.async { window.makeFirstResponder(nil) }
    }

    /// Builds into the remembered destination, or asks for one the first time.
    private func build() {
        guard let destination = store.destination else { return chooseAndBuild() }
        build(at: destination)
    }

    private func chooseAndBuild() {
        if chooseDestination(), let destination = store.destination { build(at: destination) }
    }

    /// Asks for a folder and remembers it. False when cancelled.
    private func chooseDestination() -> Bool {
        guard !isBuilding else { return false }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = store.destination
        panel.prompt = Strings.Build.panelPrompt
        panel.message = Strings.Build.panelMessage(rootFolder: store.settings.rootFolderName)
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        store.setDestination(url)
        return true
    }

    private func build(at url: URL) {
        guard !isBuilding else { return }
        isBuilding = true
        Task {
            do { builtProject = try await store.buildProject(at: url) }
            catch { buildError = error.localizedDescription }
            isBuilding = false
        }
    }
}

/// The primary action, pinned below the form in a native macOS bottom bar.
struct BuildBar: View {
    let rootFolderName: String
    /// The remembered folder; nil until the first build picks one.
    let destination: URL?
    let isBuilding: Bool
    let build: () -> Void
    let change: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Spacing.md) {
                Label(rootFolderName, systemImage: SFSymbol.folderFill)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .layoutPriority(1)      // the destination name shortens first
                if let destination {
                    Text(Strings.Build.destination(destination.lastPathComponent))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(destination.path)
                    Button(Strings.Build.change, action: change)
                        .buttonStyle(.link)
                        .help(Strings.Build.changeHelp)
                        .disabled(isBuilding)
                }
                Spacer(minLength: Spacing.md)
                if isBuilding {
                    ProgressView().controlSize(.small)
                }
                Button(destination == nil ? Strings.Build.button : Strings.Build.buildHere,
                       systemImage: SFSymbol.build, action: build)
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
// A FocusedValueKey, not `@Entry`: `@Entry` warns that a stored closure can't be
// compared, so every update would invalidate the menu command.
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
