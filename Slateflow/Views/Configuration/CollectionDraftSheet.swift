//
//  CollectionDraftSheet.swift
//  Slateflow
//
//  The "add a parameterised Smart Collection" sheet + its draft model.
//

import SwiftUI

struct CollectionDraft: Identifiable {
    enum Kind { case cameraAngle, shootDay, keyword, videoRole, audioRole }
    let id = UUID()
    var kind: Kind
    var value = ""

    var title: String {
        switch kind {
        case .cameraAngle: Strings.SmartCollections.Draft.cameraAngleTitle
        case .shootDay:    Strings.SmartCollections.Draft.shootDayTitle
        case .keyword:     Strings.SmartCollections.Draft.keywordTitle
        case .videoRole:   Strings.SmartCollections.Draft.videoRoleTitle
        case .audioRole:   Strings.SmartCollections.Draft.audioRoleTitle
        }
    }
    var prompt: String {
        switch kind {
        case .cameraAngle: Strings.SmartCollections.Draft.cameraAnglePrompt
        case .shootDay:    Strings.SmartCollections.Draft.shootDayPrompt
        case .keyword:     Strings.SmartCollections.Draft.keywordPrompt
        case .videoRole, .audioRole: Strings.SmartCollections.Draft.rolePrompt
        }
    }
    var explanation: String {
        switch kind {
        case .cameraAngle: Strings.SmartCollections.Draft.cameraAngleHelp
        case .shootDay:    Strings.SmartCollections.Draft.shootDayHelp
        case .keyword:     Strings.SmartCollections.Draft.keywordHelp
        case .videoRole, .audioRole: Strings.SmartCollections.Draft.roleHelp
        }
    }
}

struct CollectionDraftSheet: View {
    @State var draft: CollectionDraft
    let onAdd: (CollectionDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(draft.title).font(.headline)

            TextField(draft.prompt, text: $draft.value)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)

            Text(draft.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Button(Strings.SmartCollections.Draft.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(Strings.SmartCollections.Draft.add, action: add)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.value.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Spacing.lg)
        .frame(width: 340)
    }

    private func add() {
        onAdd(draft)
        dismiss()
    }
}
