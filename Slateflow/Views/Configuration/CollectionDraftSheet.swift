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

    var text: (title: String, prompt: String, help: String) {
        typealias D = Strings.SmartCollections.Draft
        switch kind {
        case .cameraAngle: return (D.cameraAngleTitle, D.cameraAnglePrompt, D.cameraAngleHelp)
        case .shootDay:    return (D.shootDayTitle, D.shootDayPrompt, D.shootDayHelp)
        case .keyword:     return (D.keywordTitle, D.keywordPrompt, D.keywordHelp)
        case .videoRole:   return (D.videoRoleTitle, D.rolePrompt, D.roleHelp)
        case .audioRole:   return (D.audioRoleTitle, D.rolePrompt, D.roleHelp)
        }
    }
}

struct CollectionDraftSheet: View {
    @State private var draft: CollectionDraft
    let onAdd: (CollectionDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    init(draft: CollectionDraft, onAdd: @escaping (CollectionDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onAdd = onAdd
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(draft.text.title).font(.headline)

            TextField(draft.text.prompt, text: $draft.value)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)

            Text(draft.text.help)
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
