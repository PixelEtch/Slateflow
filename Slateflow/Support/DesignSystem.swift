//
//  DesignSystem.swift
//  Slateflow
//
//  Central spacing, sizes, colour tokens and view-layer SF Symbol
//  names. Views reference these instead of literals. The grouped `Form`, system
//  controls and sheets keep their own spacing and rounding - these tokens are
//  only for the custom-layout surfaces (bars, tree rows, cards, sheets).
//

import SwiftUI

/// Gaps and padding: 2 · 4 · 8 · 12 · 16 · 20 · 24.
/// Spacing: a 4-pt scale (2 is the half-step for hairline gaps).
enum Spacing {
    /// 2 - hairline nudges, chip and caption line gaps
    static let xxxs: CGFloat = 2
    /// 4 - icon ↔ label, tight inline gaps
    static let xxs: CGFloat = 4
    /// 8 - default gap between related elements
    static let xs: CGFloat = 8
    /// 12 - header insets, control padding
    static let sm: CGFloat = 12
    /// 16 - bar / section horizontal padding
    static let md: CGFloat = 16
    /// 20 - grid column gutter, sheet padding
    static let lg: CGFloat = 20
    /// 24 - window padding (About)
    static let xl: CGFloat = 24
}

/// Fixed sizes, one small scale per kind.
/// Sizes follow one rule per group, so no value is a one-off:
/// small elements are multiples of 4, controls multiples of 8, and panels, sheets and
/// windows step by 40. Column and formMinWidth are set by their content instead.
enum Size {
    /// Glyph frames, multiples of 4: 12 · 20 · 64.
    enum Icon {
        /// 12 - disclosure chevron column
        static let sm: CGFloat = 12
        /// 20 - toolbar tray divider
        static let md: CGFloat = 20
        /// 64 - app icon in About, the standard macOS About size
        static let lg: CGFloat = 64
    }

    /// Control widths, multiples of 8: 80 · 240.
    enum Field {
        /// 80 - one number (width or height)
        static let sm: CGFloat = 80
        /// 240 - max width of a single-line text field in a form row
        static let md: CGFloat = 240
    }

    /// Narrowest grid column before a grid drops to one column: 140 · 160.
    enum Column {
        /// 140 - in the inspector
        static let sm: CGFloat = 140
        /// 160 - in the form
        static let md: CGFloat = 160
    }

    /// Sheet and small-window sides, in 40-pt steps: 320 · 400 · 480.
    enum Sheet {
        /// 320 - single-field input sheet
        static let sm: CGFloat = 320
        /// 400 - standard sheet, About window
        static let md: CGFloat = 400
        /// 480 - sheet with a multi-button footer
        static let lg: CGFloat = 480
    }

    /// Main window.
    enum Window {
        static let size = CGSize(width: 920, height: 640)
        static let minHeight: CGFloat = 520
        /// Narrowest the form gets with the inspector open; below this the
        /// segmented controls and the Create Project button clip.
        static let formMinWidth: CGFloat = 440
    }

    /// Settings window (⌘,); its form scrolls past this height.
    enum Settings {
        static let width: CGFloat = 520
        static let height: CGFloat = 600
    }

    /// Inspector column width, in 40-pt steps.
    enum Inspector {
        static let min: CGFloat = 320
        static let ideal: CGFloat = 360
        static let max: CGFloat = 480
    }
}

enum Palette {
    /// Directory / folder iconography.
    static let folder = Color.blue
    /// Inline validation warnings.
    static let warning = Color.orange
    /// Completed build.
    static let success = Color.green
    /// Privacy / security reassurance.
    static let secure = Color.green
    /// Destructive actions (Clear Archive).
    static let destructive = Color.red

    /// Smart-collection accent tints, keyed by what the collection filters on.
    static let sourceVideo = Color.blue
    static let sourceAudio = Color.green
    static let sourceTitles = Color.purple
    static let sourceStills = Color.orange
    static let sourceKeyword = Color.indigo
    static let sourceText = Color.teal
    static let sourceProperty = Color.pink
}

/// SF Symbols owned by the view layer. Model types (`FootageSource`,
/// `SmartCollectionSpec`) carry their own symbol names.
enum SFSymbol {
    static let folder = "folder"
    static let folderFill = "folder.fill"
    static let build = "folder.badge.plus"
    static let inspector = "sidebar.right"
    static let clearHistory = "trash"
    static let historyEmpty = "clock.arrow.circlepath"
    static let leaveInPlace = "externaldrive"
    static let copyIntoLibrary = "tray.and.arrow.down.fill"
    static let addCollection = "plus"
    static let remove = "minus.circle.fill"
    static let backup = "square.and.arrow.up.on.square"
    static let reuse = "arrow.triangle.2.circlepath"
    static let warning = "exclamationmark.triangle"
    static let disclosure = "chevron.right"
    static let privacy = "lock.shield"
    static let success = "checkmark.circle.fill"
    static let fcpxmlFile = "doc.text"
    static let textFile = "doc.plaintext"
}
