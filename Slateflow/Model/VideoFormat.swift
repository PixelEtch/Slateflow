//
//  VideoFormat.swift
//  Slateflow
//
//  Pixel dimensions + aspect-ratio math shared by the resolution presets.
//

struct VideoFormat: Equatable {
    var width: Int
    var height: Int

    var pixelDimensions: String { "\(width) × \(height)" }

    /// Reduced ratio derived from the dimensions, e.g. "16:9". "-" when unknown.
    var aspectRatio: String {
        guard width > 0, height > 0 else { return "-" }
        let d = gcd(width, height)
        return "\(width / d):\(height / d)"
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

extension VideoFormat {
    static let hd1080 = VideoFormat(width: 1920, height: 1080)
    static let k2     = VideoFormat(width: 2048, height: 1080)   // DCI 2K, as in Final Cut
    static let uhd4k  = VideoFormat(width: 3840, height: 2160)
    static let uhd8k  = VideoFormat(width: 7680, height: 4320)

    /// Clamped to a 2 px floor and rounded down to even, matching how the
    /// orientation presets are re-shaped - Final Cut rejects odd dimensions.
    static func custom(width: Int, height: Int) -> VideoFormat {
        VideoFormat(width: even(max(2, width)), height: even(max(2, height)))
    }
}

/// Why the typed custom size is invalid. The build still proceeds - `format`
/// clamps and rounds - but the form warns so the correction isn't a surprise.
enum DimensionIssue { case tooSmall, odd }

/// Shared with `AspectRatio.apply` - kept internal (not `private`) now that it
/// lives in its own file.
func even(_ n: Int) -> Int { n - (n % 2) }
