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
                    Button(Strings.FootageSources.remove, systemImage: SFSymbol.remove) {
                        store.settings.setFootageSource(source, enabled: false)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: customSources.count)

            // Full-width field + compact bordered button: fits a narrow form.
            HStack(spacing: Spacing.xs) {
                TextField(Strings.FootageSources.addLabel, text: $newSource,
                          prompt: Text(Strings.FootageSources.addPrompt))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustom)
                Button(Strings.FootageSources.add, systemImage: SFSymbol.addCollection, action: addCustom)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .help(Strings.FootageSources.add)
                    .disabled(newSource.trimmingCharacters(in: .whitespaces).isEmpty)
            }
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
