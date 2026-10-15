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
                // Footage-linked collections follow their source toggle, so only manual
                // ones get a remove button; linked rows keep its space so switches align.
                Button(Strings.SmartCollections.remove, systemImage: SFSymbol.remove) {
                    store.fcp.removeCollection(spec)
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
                    store.fcp.removeCollection(spec)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: store.fcp.smartCollections.count)

        Menu(Strings.SmartCollections.add, systemImage: SFSymbol.addCollection) {
            Button(Strings.SmartCollections.screenRecordings) {
                store.fcp.addCollection(.screenRecordings)
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
        case .cameraAngle:        store.fcp.addCollection(.cameraAngle, value: draft.value)
        case .shootDay, .keyword: store.fcp.addCollection(.keyword, value: draft.value)
        case .videoRole:          store.fcp.addRole(draft.value, to: \.videoRoles)
        case .audioRole:          store.fcp.addRole(draft.value, to: \.audioRoles)
        }
    }
}
