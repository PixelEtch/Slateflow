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

    var body: some View {
        ConfigurationForm(store: store)
            .frame(minWidth: Size.Window.formMinWidth)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BuildBar(rootFolderName: store.settings.rootFolderName,
                         isBuilding: isBuilding,
                         action: chooseAndBuild)
            }
            .inspector(isPresented: $showInspector) {
                InspectorPane(store: store, isShown: showInspector)
                    .inspectorColumnWidth(min: Size.Inspector.min, ideal: Size.Inspector.ideal, max: Size.Inspector.max)
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
            .frame(minHeight: Size.Window.minHeight)
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

    private func chooseAndBuild() {
        guard !isBuilding else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = Strings.Build.panelPrompt
        panel.message = Strings.Build.panelMessage(rootFolder: store.settings.rootFolderName)
        guard panel.runModal() == .OK, let url = panel.url else { return }

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
