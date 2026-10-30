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
            Picker(Strings.Format.resolution, selection: $store.settings.choice) {
                ForEach(ResolutionChoice.allCases) { Text($0.rawValue).tag($0) }
            }

            if store.settings.choice != .custom {
                Picker(Strings.Format.orientation, selection: $store.settings.orientation) {
                    ForEach(Orientation.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker(Strings.Format.aspectRatio, selection: $store.settings.aspect) {
                    ForEach(store.settings.orientation.ratios) { Text($0.rawValue).tag($0) }
                }
            }

            if store.settings.choice == .custom {
                LabeledContent(Strings.Format.dimensions) {
                    HStack(spacing: Spacing.xs) {
                        TextField(Strings.Format.width, value: $store.settings.customWidth, format: .number)
                            .labelsHidden().textFieldStyle(.roundedBorder).frame(width: Size.Field.sm)
                        Text(Strings.Format.dimensionSeparator).foregroundStyle(.secondary)
                        TextField(Strings.Format.height, value: $store.settings.customHeight, format: .number)
                            .labelsHidden().textFieldStyle(.roundedBorder).frame(width: Size.Field.sm)
                    }
                    .multilineTextAlignment(.trailing)
                }

                if let issue = store.settings.customDimensionsIssue {
                    // Only the icon is orange: orange caption text fails contrast on light backgrounds.
                    Label {
                        Text(issue == .tooSmall ? Strings.Format.dimensionsTooSmall
                                                : Strings.Format.dimensionsOdd)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: SFSymbol.warning).foregroundStyle(Palette.warning)
                    }
                    .font(.caption)
                }

                LabeledContent(Strings.Format.aspectRatio, value: store.settings.format.aspectRatio)
            }

            Picker(Strings.Format.frameRate, selection: $store.settings.fcp.frameRate) {
                ForEach(FrameRate.allCases) { Text($0.label).tag($0) }
            }

            LabeledContent(Strings.Format.outputSize, value: store.settings.format.pixelDimensions)

            Picker(Strings.Format.colorSpace, selection: $store.settings.fcp.colorSpace) {
                ForEach(ColorSpace.allCases) { Text($0.label).tag($0) }
            }
            .help(Strings.Format.colorSpaceHelp)

            if store.settings.canAddReelTimeline {
                // A second Text is the grouped form's subtitle line.
                Toggle(isOn: $store.settings.fcp.reelTimeline) {
                    Text(Strings.Format.reelTimeline)
                    Text(Strings.Format.reelTimelineHelp)
                }
                .toggleStyle(.switch)
            }
        }
    }
}
