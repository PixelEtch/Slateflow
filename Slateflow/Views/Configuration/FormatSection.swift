//
//  FormatSection.swift
//  Slateflow
//
//  Resolution, orientation, aspect ratio, frame rate, and custom dimensions.
//

import SwiftUI

struct FormatSection: View {
    @Bindable var store: SlateStore

    var body: some View {
        Section(Strings.Format.section) {
            Picker(Strings.Format.resolution, selection: $store.choice) {
                ForEach(ResolutionChoice.allCases) { Text($0.rawValue).tag($0) }
            }

            if store.choice != .custom {
                Picker(Strings.Format.orientation, selection: $store.orientation) {
                    ForEach(Orientation.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker(Strings.Format.aspectRatio, selection: $store.aspect) {
                    ForEach(store.orientation.ratios) { Text($0.rawValue).tag($0) }
                }
            }

            if store.choice == .custom {
                LabeledContent(Strings.Format.dimensions) {
                    HStack(spacing: Spacing.xs) {
                        TextField(Strings.Format.width, value: $store.customWidth, format: .number)
                            .labelsHidden().frame(width: 76)
                        Text(Strings.Format.dimensionSeparator).foregroundStyle(.secondary)
                        TextField(Strings.Format.height, value: $store.customHeight, format: .number)
                            .labelsHidden().frame(width: 76)
                    }
                    .multilineTextAlignment(.trailing)
                }

                if let issue = store.customDimensionsIssue {
                    Label(issue == .tooSmall ? Strings.Format.dimensionsTooSmall
                                             : Strings.Format.dimensionsOdd,
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                LabeledContent(Strings.Format.aspectRatio, value: store.format.aspectRatio)
            }

            Picker(Strings.Format.frameRate, selection: $store.fcp.frameRate) {
                ForEach(FrameRate.allCases) { Text($0.label).tag($0) }
            }

            LabeledContent(Strings.Format.outputSize, value: store.format.pixelDimensions)
        }
    }
}
