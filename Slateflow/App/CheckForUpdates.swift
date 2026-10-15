//
//  CheckForUpdates.swift
//  Slateflow
//

import SwiftUI
import Combine
import Sparkle

/// Mirrors `SPUUpdater.canCheckForUpdates` so the menu item greys out while a check runs.
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var model: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        model = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button(Strings.About.checkForUpdates) { updater.checkForUpdates() }
            .disabled(!model.canCheckForUpdates)
    }
}
