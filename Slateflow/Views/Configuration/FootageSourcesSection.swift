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
        store.settings.footageSources.filter(\.isCustom)
    }

    var body: some View {
        Section(Strings.FootageSources.section) {
            // Two columns when the form is wide enough, one when it isn't.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Size.Column.md), alignment: .leading)],
                      alignment: .leading, spacing: Spacing.xs) {
                ForEach(FootageSource.presets) { source in
                    Toggle(isOn: binding(for: source)) {
                        Label(source.folderName, systemImage: source.symbol)
                    }
                    .toggleStyle(.checkbox)
                }
            }
            .padding(.vertical, Spacing.xxs)

            ForEach(customSources) { source in
                HStack {
                    Label(source.folderName, systemImage: source.symbol)
                    Spacer()
                    RemoveButton(title: Strings.FootageSources.remove(source.folderName)) {
                        store.settings.setFootageSource(source, enabled: false)
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: customSources.count)

            AddField(label: Strings.FootageSources.addLabel, prompt: Strings.FootageSources.addPrompt,
                     addTitle: Strings.FootageSources.add, text: $newSource, onAdd: addCustom)
        }
    }

    private func addCustom() {
        store.settings.addCustomFootageSource(newSource)
        newSource = ""
    }

    private func binding(for source: FootageSource) -> Binding<Bool> {
        Binding(get: { store.settings.footageSources.contains(source) },
                set: { store.settings.setFootageSource(source, enabled: $0) })
    }
}
