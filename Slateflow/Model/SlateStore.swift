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

    /// The folder new projects go into, remembered across launches. Nil until one is
    /// chosen, or when the saved one can no longer be resolved (e.g. its drive was erased).
    private(set) var destination: URL?
    private static let destinationKey = "destinationBookmark"

    init(defaults: UserDefaults = .standard, history: SelectionHistory = SelectionHistory()) {
        self.defaults = defaults
        self.history = history
        // First assignment runs the init accessor, not `didSet`: building a store writes nothing.
        settings = SavedSettings.load(from: defaults)
        destination = Self.resolveDestination(in: defaults)
    }

    /// Remember `url` (picked in an open panel) as the destination. The sandbox only grants
    /// access to a picked folder until quit, so it's saved as an app-scoped bookmark.
    func setDestination(_ url: URL) {
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope)
            defaults.set(bookmark, forKey: Self.destinationKey)
        } catch {
            // Still usable this session; it just won't be remembered.
            Log.error("Couldn't remember destination \(url.path): \(error.localizedDescription)")
        }
        destination = url
    }

    private static func resolveDestination(in defaults: UserDefaults) -> URL? {
        guard let bookmark = defaults.data(forKey: destinationKey) else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope,
                                 bookmarkDataIsStale: &isStale) else {
            Log.error("Saved destination can't be resolved; asking again on the next build")
            return nil
        }
        // Stale: the folder moved or was renamed. The URL is still right; refresh the bookmark.
        if isStale, url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            if let fresh = try? url.bookmarkData(options: .withSecurityScope) {
                defaults.set(fresh, forKey: destinationKey)
            }
        }
        return url
    }

    /// Build the next numbered project in `destination` from one snapshot of the
    /// current configuration, then record that same snapshot in Build Archives.
    /// Nothing is written to `history` until a build succeeds.
    @discardableResult
    func buildProject(at destination: URL) async throws -> URL {
        let snapshot = settings.snapshot
        // A remembered destination needs its bookmark's access turned on; a just-picked one
        // already has access, and then this returns false.
        let scoped = destination.startAccessingSecurityScopedResource()
        defer { if scoped { destination.stopAccessingSecurityScopedResource() } }
        // Disk writes run off the main actor so the window stays responsive on slow volumes.
        let rootURL = try await Task.detached(priority: .userInitiated) {
            try ProjectLayout.build(snapshot, in: destination)
        }.value
        // Only a successful build records history - the final locked-in state.
        history.record(BuildRecord(snapshot: snapshot, rootFolder: rootURL.lastPathComponent))
        return rootURL
    }
}
