//
//  RowControls.swift
//  Slateflow
//
//  Small controls shared across the app's lists and forms, so they match everywhere.
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

/// A row title with a grey hint under it - one size and spacing for every row that
/// explains itself (Leave files in place, Folders and Smart Collections).
struct RowLabel: View {
    let title: String
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(title)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// A row that opens to show more: chevron, the whole header toggles, and the content is
/// always present and animates height and opacity, so it glides open instead of snapping.
/// Used by Recent Projects rows and the Folders list.
struct ExpandableRow<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Chevron width + the spacing after it, so content lines up under the header text.
    static var contentIndent: CGFloat { Size.Icon.sm + Spacing.xs }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Image(systemName: SFSymbol.disclosure)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: Size.Icon.sm)
                header
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: toggle)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { toggle() }

            content
                .padding(.leading, Self.contentIndent)
                .frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
                .allowsHitTesting(isExpanded)
        }
    }

    private func toggle() {
        withAnimation(reduceMotion ? nil : .snappy) { isExpanded.toggle() }
    }
}
