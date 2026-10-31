//
//  SlateflowApp.swift
//  Slateflow
//
//  Created by Sk Ashifali Shaikh on 28/8/2026.
//

import SwiftUI
import AppKit
import Sparkle
import TipKit

@main
struct SlateflowApp: App {
    // Started after the self-check so CI's --selftest run never touches the network.
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    /// Shared by the main window and Settings. Created in `init`, after the self-check.
    @State private var store: SlateStore

    init() {
        #if DEBUG
        slateSelfCheck()
        // CI entry point: a failed check traps above (non-zero exit), so reaching
        // here means every check passed.
        if CommandLine.arguments.contains("--selftest") {
            print("Slateflow self-check passed")
            exit(0)
        }
        #endif
        Log.event("Launched - \(AppInfo.versionLine)")
        _store = State(initialValue: SlateStore())
        // The one-time Customize tip; its shown/dismissed state persists across launches.
        try? Tips.configure()
        #if !DEBUG
        // Debug builds never check: an update would replace them with the release build.
        // Check for Updates… stays disabled because the updater isn't started.
        updaterController.startUpdater()
        #endif
    }

    var body: some Scene {
        // One window: reopened from the Window menu or the Dock, never duplicated.
        Window(AppInfo.name, id: "main") {
            ContentView(store: store)
        }
        .defaultSize(Size.Window.size)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
                CheckForUpdatesView(updater: updaterController.updater)
            }
            CommandGroup(replacing: .appSettings) { CustomizeProjectsCommand() }
            // Replaces New Window: ⌘N creates a project, as in other one-window apps.
            CommandGroup(replacing: .newItem) { BuildCommand() }
            // Replaces the default "Slateflow Help", which only says help isn't available.
            CommandGroup(replacing: .help) {
                Link(Strings.Help.guide, destination: AppInfo.helpURL)
                    .keyboardShortcut("?", modifiers: .command)
                Link(Strings.Help.troubleshooting, destination: AppInfo.troubleshootingURL)
                Link(Strings.Help.releaseNotes, destination: AppInfo.releaseNotesURL)
                Link(Strings.Help.privacy, destination: AppInfo.privacyURL)
                Divider()
                Link(Strings.Help.reportIssue, destination: AppInfo.reportIssueURL)
                Button(Strings.About.openLog) {
                    NSWorkspace.shared.activateFileViewerSelecting([Log.fileURL])
                }
            }
        }

        // Folders and Smart Collections every new project gets. Not called Settings: it's the
        // project template, so it has its own name, still on ⌘, (see CustomizeProjectsCommand).
        Window(Strings.Settings.title, id: SettingsTab.windowID) {
            SettingsForm(store: store)
        }
        .windowResizability(.contentSize)

        Window(Strings.About.menuItem, id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
