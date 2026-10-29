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
        ForEach($store.settings.fcp.smartCollections) { $spec in
            HStack {
                SmartCollectionRow(spec: $spec)
                // Footage-linked collections follow their source toggle, so only manual
                // ones get a remove button; linked rows keep its space so switches align.
                Button(Strings.SmartCollections.remove(spec.name), systemImage: SFSymbol.remove) {
                    store.settings.fcp.removeCollection(spec)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .opacity(spec.isFootageLinked ? 0 : 1)
                .disabled(spec.isFootageLinked)
                .accessibilityHidden(spec.isFootageLinked)
            }
            .contextMenu {
                Button(Strings.SmartCollections.remove, role: .destructive) {
                    store.settings.fcp.removeCollection(spec)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: store.settings.fcp.smartCollections.count)

        Menu(Strings.SmartCollections.add, systemImage: SFSymbol.addCollection) {
            Button(Strings.SmartCollections.screenRecordings) {
                store.settings.fcp.addCollection(.screenRecordings)
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
        switch draft.kind {
        case .cameraAngle:        store.settings.fcp.addCollection(.cameraAngle, value: draft.value)
        case .shootDay, .keyword: store.settings.fcp.addCollection(.keyword, value: draft.value)
        case .videoRole:          store.settings.fcp.addRole(draft.value, to: \.videoRoles)
        case .audioRole:          store.settings.fcp.addRole(draft.value, to: \.audioRoles)
        }
    }
}
