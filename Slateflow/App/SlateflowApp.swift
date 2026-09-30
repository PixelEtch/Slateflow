//
//  SlateflowApp.swift
//  Slateflow
//
//  Created by Sk Ashifali Shaikh on 28/8/2026.
//

import SwiftUI
import AppKit

@main
struct SlateflowApp: App {
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 640)
        .commands {
            CommandGroup(replacing: .appInfo) { AboutMenuButton() }
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
