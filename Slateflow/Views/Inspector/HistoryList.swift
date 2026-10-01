//
//  HistoryList.swift
//  Slateflow
//
//  Build Archives list - reuse/delete a saved project configuration.
//

import SwiftUI

struct HistoryList: View {
    @Bindable var store: SlateStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var history: SelectionHistory { store.history }

    var body: some View {
        if history.builds.isEmpty {
            ContentUnavailableView {
                Label(Strings.History.emptyTitle, systemImage: SFSymbol.historyEmpty)
            } description: {
                Text(Strings.History.emptyMessage)
            }
        } else {
            // Plain ScrollView + LazyVStack, not List: List is backed by NSTableView
            // on macOS, which doesn't smoothly animate row-height changes no matter
            // the technique - this is pure SwiftUI layout, so it actually animates.
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(history.builds.reversed()) { record in
                        HistoryRow(record: record,
                                  onReuse: { store.applyConfiguration(from: record) },
                                  onDelete: { history.remove(record) })
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .contextMenu {
                                Button(Strings.History.reuse) { store.applyConfiguration(from: record) }
                                Button(Strings.History.delete, role: .destructive) {
                                    history.remove(record)
                                }
                            }
                    }
                }
                .animation(reduceMotion ? nil : .snappy, value: history.builds.count)
            }
            // Pinned below the list, so it stays visible however long the archive gets.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Text(Strings.History.storageNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(.bar)
            }
        }
    }
}
