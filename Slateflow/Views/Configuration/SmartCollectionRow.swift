//
//  SmartCollectionRow.swift
//  Slateflow
//
//  One Smart Collection row + its view-layer accent tint.
//

import SwiftUI

struct SmartCollectionRow: View {
    @Binding var spec: SmartCollectionSpec

    // Built as label + switch (not `Toggle { label }`), so the switch centres on the
    // two-line row instead of sitting beside the first line.
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(spec.name)
                    Text(spec.isFootageLinked
                         ? "\(spec.summary) · \(Strings.SmartCollections.fromFootageSources)"
                         : spec.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: spec.iconName)
                    .foregroundStyle(spec.enabled ? spec.tint : Color.secondary)
            }
            Spacer()
            Toggle(spec.name, isOn: $spec.enabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

extension SmartCollectionSpec {
    /// View-layer accent tint, chosen from what the collection filters on.
    var tint: Color {
        let name = name.lowercased()
        if name.contains("title") { return Palette.sourceTitles }
        if ["music", "dialogue", "audio", "sound", "effects"].contains(where: name.contains) {
            return Palette.sourceAudio
        }
        switch rules.first {
        case .mediaType("stills"):     return Palette.sourceStills
        case .keywords:                return Palette.sourceKeyword
        case .text:                    return Palette.sourceText
        case .property:                return Palette.sourceProperty
        default:                       return Palette.sourceVideo
        }
    }
}
