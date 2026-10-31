//
//  HistoryRow.swift
//  Slateflow
//
//  One collapsible Build Archive row: summary + reuse/delete actions.
//

import SwiftUI

struct HistoryRow: View {
    let record: BuildRecord
    let onReuse: () -> Void
    let onDelete: () -> Void
    @State private var isExpanded = false

    var body: some View {
        ExpandableRow(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Label(record.rootFolder, systemImage: SFSymbol.folderFill)
                    .font(.headline)
                Text(formatSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.time, format: .dateTime.month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        } content: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Two columns when the inspector is wide enough; one column when it isn't.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Size.Column.sm), spacing: Spacing.lg, alignment: .leading)],
                          alignment: .leading, spacing: Spacing.xxs) {
                    ForEach(statItems, id: \.label) { cell($0.label, $0.value) }
                }

                Label(record.leaveFilesInPlace ? Strings.History.leaveFilesInPlace
                                               : Strings.History.copyIntoLibrary,
                      systemImage: record.leaveFilesInPlace ? SFSymbol.leaveInPlace
                                                            : SFSymbol.copyIntoLibrary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: Spacing.sm) {
                    Button(Strings.History.reuse, systemImage: SFSymbol.reuse, action: onReuse)
                        .help(Strings.History.reuseHelp)
                    Button(Strings.History.delete, systemImage: SFSymbol.clearHistory,
                          role: .destructive, action: onDelete)
                }
                .controlSize(.small)
                .buttonStyle(.bordered)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// "4K · 16:9 · 25 fps" - the format subtitle is Custom-aware: Custom builds have
    /// no orientation, so the subtitle falls back to just size + frame rate.
    private var formatSubtitle: String {
        let resolution = record.resolution == "Custom" ? record.dimensions : record.resolution
        return [resolution, record.aspectRatio, record.frameRate].joined(separator: " · ")
    }

    private var statItems: [(label: String, value: String)] {
        [(Strings.History.orientation, record.orientation),
         (Strings.History.size, record.dimensions),
         (Strings.History.roles, "\(record.roleCount)"),
         (Strings.History.collections, "\(record.collectionCount)"),
         (Strings.History.footageSources, "\(record.footageSourceCount)")]
    }

    private func cell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout)
        }
    }
}
