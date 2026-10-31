//
//  SettingsForm.swift
//  Slateflow
//
//  The Customize Projects window (⌘,): options set once and rarely changed - the project’s
//  folders and the Final Cut setup. Shares the main window's store.
//

import SwiftUI

/// The Settings tab, remembered so Customize… and the Edit links open the right one.
enum SettingsTab: String, CaseIterable {
    case folders, smartCollections

    var title: String {
        switch self {
        case .folders: Strings.Folders.section
        case .smartCollections: Strings.SmartCollections.section
        }
    }

    /// ⌘1, ⌘2 - as in Apple's own Settings windows.
    var shortcut: KeyEquivalent {
        switch self {
        case .folders: "1"
        case .smartCollections: "2"
        }
    }

    static let storageKey = "settingsTab"
    static let windowID = "customize"
}

struct SettingsForm: View {
    @Bindable var store: SlateStore
    @AppStorage(SettingsTab.storageKey) private var tab = SettingsTab.folders
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far the pill is being dragged, in points, from its tab.
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            tabSwitch
                .padding(.top, Spacing.md)
            // Both tabs stay loaded and switching only fades them, as the main window's
            // inspector panes do: rebuilding a list mid-switch made the pill stutter.
            ZStack {
                Form { FoldersSection(store: store) }
                    .formStyle(.grouped)
                    .tabVisible(tab == .folders)
                smartCollections
                    .tabVisible(tab == .smartCollections)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: tab)
        }
        // ⌘1 / ⌘2 switch tabs; invisible and out of the Tab order and VoiceOver.
        .background {
            ForEach(SettingsTab.allCases, id: \.self) { item in
                Button(item.title) { select(item) }
                    .keyboardShortcut(item.shortcut, modifiers: .command)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .focusable(false)
                    .allowsHitTesting(false)
            }
        }
        // No Save button, as in macOS Settings: every change is stored as it's made.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // A bar, like the main window's bottom bar, so the list scrolls under it.
            VStack(spacing: 0) {
                Divider()
                Text(Strings.Settings.autosave)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(.bar)
            }
        }
        .frame(width: Size.Settings.width, height: Size.Settings.height)
    }

    private func select(_ item: SettingsTab) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { tab = item }
    }

    /// macOS 26: a glass track with a pill you can click or drag to a tab; it follows the
    /// pointer and snaps to the nearest tab on release. The glass sits behind the labels
    /// (glass over text blurs it). Before 26: the system segmented control. Either way
    /// VoiceOver sees a two-option switch.
    @ViewBuilder private var tabSwitch: some View {
        if #available(macOS 26, *) {
            let width = Size.Settings.tabWidth
            let tabs = SettingsTab.allCases
            let index = CGFloat(tabs.firstIndex(of: tab) ?? 0)
            let maxOffset = CGFloat(tabs.count - 1) * width
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { item in
                    Button { select(item) } label: {
                        Text(item.title)
                            .foregroundStyle(tab == item ? .primary : .secondary)
                            .frame(width: width)
                            .padding(.vertical, Spacing.xs)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(width: width)
                    .offset(x: min(max(index * width + dragOffset, 0), maxOffset))
            }
            .padding(Spacing.xxxs)
            .glassEffect(.regular, in: .capsule)
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { dragOffset = $0.translation.width }
                    .onEnded { drag in
                        let landed = ((index * width + drag.translation.width) / width).rounded()
                        let target = tabs[Int(min(max(landed, 0), CGFloat(tabs.count - 1)))]
                        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
                            tab = target
                            dragOffset = 0
                        }
                    }
            )
            .accessibilityRepresentation { segmentedPicker }
        } else {
            segmentedPicker
                .controlSize(.large)
                .fixedSize()
                .tint(Color(nsColor: .tertiaryLabelColor))   // grey, not the accent blue
        }
    }

    private var segmentedPicker: some View {
        Picker(Strings.Settings.tabs, selection: $tab) {
            ForEach(SettingsTab.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var smartCollections: some View {
        Form {
            Section {
                // Same shape as a collection row: text, then a centred switch.
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(Strings.FCP.leaveFilesInPlace)
                        Text(Strings.FCP.leaveFilesInPlaceHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(Strings.FCP.leaveFilesInPlace, isOn: $store.settings.fcp.keepMediaInPlace)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    // Same trailing space as a collection's remove button, so the
                    // switches below line up with this one.
                    Image(systemName: SFSymbol.remove).hidden()
                }
                SmartCollectionsSection(store: store)
            } footer: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.SmartCollections.footer)
                    Text(Strings.FCP.finalCutHints)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private extension View {
    /// Shown, or hidden but still loaded: invisible, not clickable, skipped by VoiceOver.
    func tabVisible(_ visible: Bool) -> some View {
        opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
    }
}

/// Opens Settings on `tab` - for links to options that live there.
struct SettingsButton: View {
    let title: String
    let tab: SettingsTab
    @AppStorage(SettingsTab.storageKey) private var settingsTab = SettingsTab.folders
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(title) {
            settingsTab = tab
            openWindow(id: SettingsTab.windowID)
        }
    }
}

/// Slateflow ▸ Customize Projects… (⌘,), in place of the standard Settings… item.
struct CustomizeProjectsCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(Strings.Settings.menuItem) { openWindow(id: SettingsTab.windowID) }
            .keyboardShortcut(",", modifiers: .command)
    }
}

#Preview {
    SettingsForm(store: SlateStore())
}
