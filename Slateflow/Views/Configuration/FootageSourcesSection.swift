//
//  FootageSourcesSection.swift
//  Slateflow
//
//  Preset camera/capture sources + user-typed custom ones.
//

import SwiftUI

struct FootageSourcesSection: View {
    @Bindable var store: SlateStore
    @State private var newSource = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var customSources: [FootageSource] {
        store.footageSources.filter(\.isCustom)
    }

    var body: some View {
        Section(Strings.FootageSources.section) {
            ForEach(FootageSource.presets) { source in
                Toggle(isOn: binding(for: source)) {
                    Label(source.folderName, systemImage: source.symbol)
                }
            }

            ForEach(customSources) { source in
                HStack {
                    Label(source.folderName, systemImage: source.symbol)
                    Spacer()
                    Button(Strings.FootageSources.remove, systemImage: SFSymbol.remove) {
                        store.setFootageSource(source, enabled: false)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing) {
                    Button(Strings.FootageSources.remove, role: .destructive) {
                        store.setFootageSource(source, enabled: false)
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: customSources.count)

            HStack {
                TextField(Strings.FootageSources.addPrompt, text: $newSource)
                    .onSubmit(addCustom)
                Button(Strings.FootageSources.add, systemImage: SFSymbol.addCollection, action: addCustom)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .disabled(newSource.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addCustom() {
        store.addCustomFootageSource(newSource)
        newSource = ""
    }

    private func binding(for source: FootageSource) -> Binding<Bool> {
        Binding(get: { store.footageSources.contains(source) },
                set: { store.setFootageSource(source, enabled: $0) })
    }
}
