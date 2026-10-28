//
//  SlateflowApp.swift
//  Slateflow
//
//  Created by Sk Ashifali Shaikh on 28/8/2026.
//

import SwiftUI
import AppKit
import Sparkle

@main
struct SlateflowApp: App {
    // Started after the self-check so CI's --selftest run never touches the network.
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

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
        #if !DEBUG
        // Debug builds never check: an update would replace them with the release build.
        // Check for Updates… stays disabled because the updater isn't started.
        updaterController.startUpdater()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(Size.Window.size)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
                CheckForUpdatesView(updater: updaterController.updater)
            }
            CommandGroup(after: .newItem) { BuildCommand() }
            CommandGroup(after: .help) {
                Button(Strings.About.openLog) {
                    NSWorkspace.shared.activateFileViewerSelecting([Log.fileURL])
                }
            }
        }

        Window(Strings.About.menuItem, id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
