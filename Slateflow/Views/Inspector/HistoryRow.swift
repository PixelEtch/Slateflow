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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Chevron width + the HStack spacing after it — lets the expanded content
    /// align under the title text, not under the chevron.
    private static let contentIndent: CGFloat = 10 + Spacing.xs

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 10)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: Spacing.xxs / 2) {
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .snappy) { isExpanded.toggle() }
            }

            // Always present (never inserted/removed) — List on macOS snaps row
            // height instead of animating it when a child is conditionally added;
            // animating height + opacity on a permanent view avoids that jump.
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Two columns when the inspector is wide enough; one column when it isn't.
                ViewThatFits(in: .horizontal) {
                    stats(twoColumn: true).frame(minWidth: 320, alignment: .leading)
                    stats(twoColumn: false)
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
            .padding(.leading, Self.contentIndent)
            .frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
            .opacity(isExpanded ? 1 : 0)
            .clipped()
            .allowsHitTesting(isExpanded)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// "4K · 16:9 · 25 fps" — the format subtitle is Custom-aware: Custom builds have
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

    @ViewBuilder
    private func stats(twoColumn: Bool) -> some View {
        let items = statItems
        let perRow = twoColumn ? 2 : 1
        Grid(alignment: .leading, horizontalSpacing: Spacing.lg, verticalSpacing: Spacing.xxs) {
            ForEach(Array(stride(from: 0, to: items.count, by: perRow)), id: \.self) { start in
                GridRow {
                    ForEach(start..<min(start + perRow, items.count), id: \.self) { i in
                        cell(items[i].label, items[i].value)
                    }
                }
            }
        }
    }

    private func cell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs / 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout)
        }
    }
}
