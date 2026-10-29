//
//  SlateStore.swift
//  Slateflow
//
//  The app's single source of truth: the saved settings, Build Archives, and the build.
//

import Foundation

@MainActor
@Observable
final class SlateStore {
    @ObservationIgnored private let defaults: UserDefaults

    /// Everything the form configures, with its rules - see `SavedSettings`. Saved whole
    /// on every change. Views bind straight to its fields and call its intents.
    var settings: SavedSettings {
        didSet { settings.save(to: defaults) }
    }

    let history: SelectionHistory

    init(defaults: UserDefaults = .standard, history: SelectionHistory = SelectionHistory()) {
        self.defaults = defaults
        self.history = history
        // First assignment runs the init accessor, not `didSet`: building a store writes nothing.
        settings = SavedSettings.load(from: defaults)
    }

    /// Build the next numbered project in `destination` from one snapshot of the
    /// current configuration, then record that same snapshot in Build Archives.
    /// Nothing is written to `history` until a build succeeds.
    @discardableResult
    func buildProject(at destination: URL) async throws -> URL {
        let snapshot = settings.snapshot
        // Disk writes run off the main actor so the window stays responsive on slow volumes.
        let rootURL = try await Task.detached(priority: .userInitiated) {
            try ProjectLayout.build(snapshot, in: destination)
        }.value
        // Only a successful build records history - the final locked-in state.
        history.record(BuildRecord(snapshot: snapshot, rootFolder: rootURL.lastPathComponent))
        return rootURL
    }
}
