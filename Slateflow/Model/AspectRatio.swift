//
//  AspectRatio.swift
//  Slateflow
//
//  Orientation + aspect-ratio selection, and the resolution picker enum.
//

/// Primary frame-shape control. Picks which family of aspect ratios is offered.
enum Orientation: String, CaseIterable, Identifiable {
    case landscape = "Landscape"
    case portrait  = "Portrait"
    case vertical  = "Vertical"
    var id: String { rawValue }

    /// Aspect ratios offered for this orientation, default first.
    var ratios: [AspectRatio] {
        switch self {
        case .landscape: [.wide169, .ultrawide219, .cinema239, .classic43, .square11]
        case .portrait:  [.social45, .classic34, .square11]
        case .vertical:  [.vertical916, .vertical921]
        }
    }
    var defaultRatio: AspectRatio { ratios[0] }
}

/// The exact ratio within an orientation. The resolution *tier* (the shorter
/// reference edge: 1080p→1080, 4K→2160, 8K→4320) is kept and the other edge is
/// derived; odd results round down - Final Cut rejects odd sizes.
// ponytail: edit the ratios here if your house definitions differ - nothing
// else depends on the specific numbers.
enum AspectRatio: String, CaseIterable, Identifiable {
    case wide169      = "16:9"
    case ultrawide219 = "21:9"
    case cinema239    = "2.39:1"
    case classic43    = "4:3"
    case square11     = "1:1"
    case classic34    = "3:4"
    case social45     = "4:5"
    case vertical916  = "9:16"
    case vertical921  = "9:21"
    var id: String { rawValue }

    /// Reduced width : height.
    var ratio: (w: Int, h: Int) {
        switch self {
        case .wide169:      (16, 9)
        case .ultrawide219: (21, 9)
        case .cinema239:    (239, 100)
        case .classic43:    (4, 3)
        case .square11:     (1, 1)
        case .classic34:    (3, 4)
        case .social45:     (4, 5)
        case .vertical916:  (9, 16)
        case .vertical921:  (9, 21)
        }
    }

    func apply(to base: VideoFormat) -> VideoFormat {
        let (w, h) = ratio
        let tier = min(base.width, base.height)
        return w >= h
            ? VideoFormat(width: even(tier * w / h), height: tier)
            : VideoFormat(width: tier, height: even(tier * h / w))
    }
}

/// The thing the user picks. Kept separate from `VideoFormat` so the picker
/// has a plain `CaseIterable` selection and `custom` can carry its own dimensions.
enum ResolutionChoice: String, CaseIterable, Identifiable {
    case hd1080 = "1080p", k2 = "2K", uhd4k = "4K", uhd8k = "8K", custom = "Custom"
    var id: String { rawValue }

    var preset: VideoFormat? {
        switch self {
        case .hd1080: return .hd1080
        case .k2:     return .k2
        case .uhd4k:  return .uhd4k
        case .uhd8k:  return .uhd8k
        case .custom: return nil
        }
    }
}
