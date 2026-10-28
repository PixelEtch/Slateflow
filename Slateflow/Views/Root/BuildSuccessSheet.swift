//
//  BuildSuccessSheet.swift
//  Slateflow
//
//  Shown after a build. Open in Final Cut Pro opens the project; Final Cut creates
//  its library in the project's FCP folder, and the sheet closes once it exists.
//

import SwiftUI

struct BuildSuccessSheet: View {
    let rootFolder: String
    /// Opens the project in Final Cut; true once Final Cut has created the library.
    let onOpen: () async -> Bool
    let onReveal: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    @State private var failed = false
    /// Cancelled when the sheet closes, so Done stops waiting for the library.
    @State private var openTask: Task<Void, Never>?

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
            Text(failed ? Strings.Build.libraryFailed : Strings.Build.libraryNote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(Strings.Build.reveal) { onReveal() }
                Spacer()
                Button(Strings.Build.done) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button {
                    open()
                } label: {
                    if isWorking {
                        HStack(spacing: Spacing.xs) { ProgressView().controlSize(.small); Text(Strings.Build.creatingLibrary) }
                    } else {
                        Text(Strings.Build.openInFCP)
                    }
                }
                .disabled(isWorking)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .frame(width: Size.Sheet.lg)
        .onDisappear { openTask?.cancel() }
    }

    private func open() {
        isWorking = true
        failed = false
        openTask = Task {
            let created = await onOpen()
            guard !Task.isCancelled else { return }
            isWorking = false
            if created { dismiss() } else { failed = true }
        }
    }
}

#Preview {
    BuildSuccessSheet(rootFolder: "002 - Herdsman", onOpen: { false }, onReveal: {})
}
