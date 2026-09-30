//
//  BuildSuccessSheet.swift
//  Slateflow
//
//  Shown after a build: what to click in Final Cut's library dialog, with the
//  exact controls called out so they're easy to spot there.
//

import SwiftUI

struct BuildSuccessSheet: View {
    let rootFolder: String
    let onOpen: () -> Void
    let onReveal: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(Strings.Build.successTitle).font(.headline)
                    Text(rootFolder).font(.callout).fontDesign(.monospaced).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: SFSymbol.success).font(.title2).foregroundStyle(Palette.success)
            }

            Divider()

            Text(Strings.Build.nextStepsTitle).font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: Spacing.xs) {
                step(1) { Text(Strings.Build.stepOpen) }
                step(2) { HStack(spacing: Spacing.xxs) { Text(Strings.Build.stepClick); Chip(Strings.Build.fcpNew) } }
                step(3) {
                    HStack(spacing: Spacing.xxs) {
                        Text(Strings.Build.stepPaste); Chip(Strings.Build.pasteShortcut)
                        Text(Strings.Build.stepThen); Chip(Strings.Build.fcpSave)
                    }
                }
            }

            HStack {
                Button(Strings.Build.reveal) { onReveal() }
                Spacer()
                Button(Strings.Build.done) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(Strings.Build.openInFCP) {
                    onOpen()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .frame(width: 460)
    }

    private func step(_ number: Int, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(.fill.secondary, in: .circle)
            content()
        }
    }
}

/// A Final Cut control or shortcut, drawn like a button so it's recognisable there.
private struct Chip: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs / 2)
            .foregroundStyle(.tint)
            .background(.tint.opacity(0.15), in: .rect(cornerRadius: 6))
    }
}

#Preview {
    BuildSuccessSheet(rootFolder: "002 - Herdsman", onOpen: {}, onReveal: {})
}
