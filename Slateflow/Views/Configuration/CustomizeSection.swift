//
//  CustomizeSection.swift
//  Slateflow
//
//  One row that says what Customize Projects holds - the folders and Smart Collections every
//  project gets - so first-time users find it. Customize… opens that window.
//

import SwiftUI
import TipKit

struct CustomizeSection: View {
    let store: SlateStore

    var body: some View {
        // A titled section like the others, so the gap above it matches theirs.
        Section(Strings.Customize.title) {
            LabeledContent {
                SettingsButton(title: Strings.Customize.button, tab: .folders)
            } label: {
                Text(Strings.Customize.summary(
                    folders: store.settings.folders.count,
                    collections: store.settings.fcp.smartCollections.filter(\.enabled).count))
            }
            .popoverTip(CustomizeTip())
        }
    }
}

/// Shown once, the first time the window opens; dismissing it or opening Customize Projects ends it.
struct CustomizeTip: Tip {
    var title: Text { Text(Strings.Customize.tipTitle) }
    var message: Text? { Text(Strings.Customize.tipMessage) }
}
