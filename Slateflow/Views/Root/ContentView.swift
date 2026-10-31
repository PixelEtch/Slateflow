//
//  ContentView.swift
//  Slateflow
//
//  Root scene: configuration form + bottom build bar + trailing inspector.
//

import SwiftUI
import AppKit

struct ContentView: View {
    /// Owned by the App, so the Settings window edits the same settings.
    @Bindable var store: SlateStore
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
            // ⌘N is the menu's shortcut; ⌘B, the shortcut before it, still works.
            .background {
                Button(Strings.Build.menuItem, action: build)
                    .keyboardShortcut("b", modifiers: .command)
                    .disabled(isBuilding)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .focusable(false)           // out of the Tab order
                    .allowsHitTesting(false)    // the shortcut still fires
            }
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
            .onAppear(perform: EndEditingOnOutsideClick.install)
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
                // One sentence: Creates “NNN - Name” in **Folder** · Change…
                HStack(spacing: Spacing.xxs) {
                    if let destination {
                        Text(Strings.Build.creates(rootFolderName))
                            .layoutPriority(1)      // the destination folder's name shortens first
                        Text(destination.lastPathComponent)
                            .fontWeight(.semibold)
                            .help(destination.path)
                        Text(Strings.Build.separator)
                            .fixedSize()
                            .accessibilityHidden(true)
                        Button(Strings.Build.change, action: change)
                            .buttonStyle(.link)
                            .foregroundStyle(.tint)     // the sentence is secondary; keep the link blue
                            .help(Strings.Build.changeHelp)
                            .disabled(isBuilding)
                            .fixedSize()
                    } else {
                        Label(rootFolderName, systemImage: SFSymbol.folderFill)
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                Spacer(minLength: Spacing.md)
                if isBuilding {
                    ProgressView().controlSize(.small)
                }
                createButton
                    .controlSize(.large)
                    .disabled(isBuilding)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.bar)
        }
    }

    /// Liquid Glass on macOS 26, as the window's main action; the classic prominent style before.
    @ViewBuilder private var createButton: some View {
        let button = Button(destination == nil ? Strings.Build.button : Strings.Build.buildHere,
                            systemImage: SFSymbol.build, action: build)
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Click outside to end editing

/// Clicking anywhere that isn't a text field ends text editing, as in System Settings.
/// AppKit keeps the cursor in a field until another control takes focus.
enum EndEditingOnOutsideClick {
    private static var monitor: Any?

    static func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let window = event.window,
                  window.firstResponder is NSText,          // a field is being edited
                  !isText(window.contentView?.hitTest(event.locationInWindow))
            else { return event }
            // After the click is handled, so a button or switch still gets it.
            DispatchQueue.main.async {
                if window.firstResponder is NSText { window.makeFirstResponder(nil) }
            }
            return event
        }
    }

    /// True for a text field or its field editor, or anything inside one.
    private static func isText(_ view: NSView?) -> Bool {
        var view = view
        while let v = view {
            if v is NSText || v is NSTextField { return true }
            view = v.superview
        }
        return false
    }
}

// MARK: - Menu-bar wiring

/// Lets the `Create Project…` menu command trigger the same flow as the bottom bar.
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
            .keyboardShortcut("n", modifiers: .command)
            .disabled(buildAction == nil)
    }
}

#Preview {
    ContentView(store: SlateStore())
}
