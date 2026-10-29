//
//  BuildSnapshot.swift
//  Slateflow
//
//  The configuration one build uses, captured once before any disk I/O.
//

import Foundation

/// Everything a build needs, taken from `SavedSettings` on the main actor before writing.
/// The folders, `Slate Project.json` and the Build Archives entry all derive from this
/// one value, so an edit made while a build runs can't make them disagree.
nonisolated struct BuildSnapshot {
    /// Sanitised: a single safe path component.
    let templateName: String
    let choice: ResolutionChoice
    let orientation: Orientation
    let aspect: AspectRatio
    let format: VideoFormat
    let fcp: FCPLibrarySettings
    let footageSources: [FootageSource]

    /// Custom sizes have no orientation or preset aspect; records show "-" for them.
    var orientationLabel: String { choice == .custom ? "-" : orientation.rawValue }
}

extension SavedSettings {
    var snapshot: BuildSnapshot {
        BuildSnapshot(
            templateName: safeTemplateName,
            choice: choice, orientation: orientation, aspect: aspect, format: format,
            fcp: fcp, footageSources: orderedFootageSources)
    }
}
