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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2),
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
                        store.setFootageSource(source, enabled: false)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: customSources.count)

            LabeledContent(Strings.FootageSources.addLabel) {
                HStack(spacing: Spacing.xs) {
                    TextField(Strings.FootageSources.addLabel, text: $newSource,
                              prompt: Text(Strings.FootageSources.addPrompt))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: Spacing.fieldWidth)
                        .onSubmit(addCustom)
                    Button(Strings.FootageSources.add, systemImage: SFSymbol.addCollection, action: addCustom)
                        .labelStyle(.titleAndIcon)
                        .disabled(newSource.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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
