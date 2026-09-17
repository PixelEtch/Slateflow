//
//  DesignSystem.swift
//  Slateflow
//
//  Central spacing scale, colour tokens, and view-layer SF Symbol names.
//  Views reference these instead of literals. The grouped `Form` owns its own
//  section spacing — `Spacing` is only for the custom-layout surfaces
//  (bars, inspector header, tree rows, cards, sheet).
//

import SwiftUI

enum Spacing {
    /// 4 — icon ↔ label, tight inline gaps
    static let xxs: CGFloat = 4
    /// 8 — default gap between related elements
    static let xs: CGFloat = 8
    /// 12 — header insets, control padding
    static let sm: CGFloat = 12
    /// 16 — bar / section horizontal padding
    static let md: CGFloat = 16
    /// 20 — grid column gutter, sheet padding
    static let lg: CGFloat = 20
}

enum Palette {
    /// Directory / folder iconography.
    static let folder = Color.blue

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
}
