//
//  FinalCutLibrary.swift
//  Slateflow
//
//  Opens a project's .fcpxml in Final Cut Pro. Its `library location` import
//  option makes Final Cut create the library in the project's FCP folder
//  (ADR 0006), so the library always matches the installed Final Cut version.
//

import AppKit

enum FinalCutLibrary {
    /// Opens the project's .fcpxml in Final Cut, then waits for Final Cut to create
    /// `<root>.fcpbundle` in the project's FCP folder. Returns true once it exists.
    /// Stops early when its task is cancelled (the success sheet closed).
    static func open(project root: URL) async -> Bool {
        let fcpxml = ProjectLayout.fcpxmlURL(root: root)
        let library = fcpxml.deletingPathExtension().appendingPathExtension("fcpbundle")
        // The plain Bool-returning `open(_:)` doesn't reliably bring a running app forward.
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        do {
            try await NSWorkspace.shared.open(fcpxml, configuration: config)
        } catch {
            Log.error("Open in Final Cut failed for \(fcpxml.lastPathComponent): \(error.localizedDescription)")
            return false
        }
        // A cold Final Cut launch takes a while; creating the library is quick after that.
        let deadline = Date.now.addingTimeInterval(60)
        while Date.now < deadline, !Task.isCancelled {
            if FileManager.default.fileExists(atPath: library.path) { return true }
            try? await Task.sleep(for: .milliseconds(500))
        }
        if !Task.isCancelled {
            Log.error("Final Cut library: \(library.lastPathComponent) didn't appear in \(library.deletingLastPathComponent().path)")
        }
        return false
    }
}
