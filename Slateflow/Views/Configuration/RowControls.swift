//
//  RowControls.swift
//  Slateflow
//
//  Small controls shared by the Cameras, Folders and Smart Collections lists.
//

import SwiftUI

/// The grey minus at the end of a row. The title names the item, so VoiceOver says
/// what's removed ("Remove Admin › Scripts").
struct RemoveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: SFSymbol.remove, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
    }
}

/// A full-width text field and a + button, for adding a camera or a folder. Return adds
/// too; the button is off while the field is blank.
struct AddField: View {
    let label: String
    let prompt: String
    let addTitle: String
    @Binding var text: String
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TextField(label, text: $text, prompt: Text(prompt))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .onSubmit(onAdd)
            Button(addTitle, systemImage: SFSymbol.addCollection, action: onAdd)
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .help(addTitle)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
