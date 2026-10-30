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
enum Size {
    /// Glyph frames: 10 · 20 · 72.
    enum Icon {
        /// 10 - disclosure chevron column
        static let sm: CGFloat = 10
        /// 20 - toolbar tray divider
        static let md: CGFloat = 20
        /// 72 - app icon in About
        static let lg: CGFloat = 72
    }

    /// Control widths: 80 · 220.
    enum Field {
        /// 80 - one number (width or height)
        static let sm: CGFloat = 80
        /// 220 - max width of a single-line text field in a form row
        static let md: CGFloat = 220
    }

    /// Narrowest grid column before a grid drops to one column: 140 · 160.
    enum Column {
        /// 140 - in the inspector
        static let sm: CGFloat = 140
        /// 160 - in the form
        static let md: CGFloat = 160
    }

    /// Sheet and small-window sides: 340 · 420 · 460.
    enum Sheet {
        /// 340 - single-field input sheet
        static let sm: CGFloat = 340
        /// 420 - standard sheet, About window
        static let md: CGFloat = 420
        /// 460 - sheet with a multi-button footer
        static let lg: CGFloat = 460
    }

    /// Main window.
    enum Window {
        static let size = CGSize(width: 900, height: 640)
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

    /// Inspector column width.
    enum Inspector {
        static let min: CGFloat = 300
        static let ideal: CGFloat = 350
        static let max: CGFloat = 460
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
    static let finalCut = "film"
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
