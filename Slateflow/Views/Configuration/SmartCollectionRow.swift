//
//  SmartCollectionRow.swift
//  Slateflow
//
//  One Smart Collection row + its view-layer accent tint.
//

import SwiftUI

struct SmartCollectionRow: View {
    @Binding var spec: SmartCollectionSpec

    var body: some View {
        Toggle(isOn: $spec.enabled) {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxs / 2) {
                    HStack(spacing: Spacing.xxs) {
                        Text(spec.name)
                        if spec.isFootageLinked {
                            Image(systemName: SFSymbol.footageLinked)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .help(Strings.SmartCollections.footageLinkedHelp)
                        }
                    }
                    Text(spec.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: spec.iconName)
                    .foregroundStyle(spec.enabled ? spec.tint : Color.secondary)
            }
        }
        .help(spec.summary)
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
