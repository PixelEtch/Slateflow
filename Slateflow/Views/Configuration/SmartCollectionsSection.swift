//
//  SmartCollectionsSection.swift
//  Slateflow
//
//  Smart Collections list rows + the "add" menu and its sheet.
//

import SwiftUI

struct SmartCollectionsSection: View {
    @Bindable var store: SlateStore
    @State private var draft: CollectionDraft?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ForEach($store.fcp.smartCollections) { $spec in
            HStack {
                SmartCollectionRow(spec: $spec)
                // Footage-linked collections follow their source toggle, so only
                // manual ones get a visible remove button.
                if !spec.isFootageLinked {
                    Button(Strings.SmartCollections.remove, systemImage: SFSymbol.remove) {
                        store.removeCollection(spec)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                Button(Strings.SmartCollections.remove, role: .destructive) {
                    store.removeCollection(spec)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: store.fcp.smartCollections.count)

        Menu(Strings.SmartCollections.add, systemImage: SFSymbol.addCollection) {
            Button(Strings.SmartCollections.screenRecordings) {
                store.addQuickCollection(.nameContains, value: Strings.SmartCollections.screenRecordingsValue)
            }
            Divider()
            Button(Strings.SmartCollections.byCameraAngle) { draft = CollectionDraft(kind: .cameraAngle) }
            Button(Strings.SmartCollections.byShootDay)    { draft = CollectionDraft(kind: .shootDay) }
            Button(Strings.SmartCollections.byKeyword)     { draft = CollectionDraft(kind: .keyword) }
            Divider()
            Button(Strings.SmartCollections.videoRole) { draft = CollectionDraft(kind: .videoRole) }
            Button(Strings.SmartCollections.audioRole) { draft = CollectionDraft(kind: .audioRole) }
        }
        .sheet(item: $draft) { CollectionDraftSheet(draft: $0, onAdd: apply) }
    }

    private func apply(_ draft: CollectionDraft) {
        let value = draft.value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return }
        switch draft.kind {
        case .cameraAngle: store.addQuickCollection(.cameraAngle, value: value)
        case .shootDay:    store.addQuickCollection(.day, value: value)
        case .keyword:     store.addQuickCollection(.keyword, value: value)
        case .videoRole:   store.addRole(name: value, kind: .video)
        case .audioRole:   store.addRole(name: value, kind: .audio)
        }
    }
}
