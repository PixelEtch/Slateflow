//
//  FootageSource.swift
//  Slateflow
//
//  Camera / capture sources - presets and user-typed customs.
//

/// A camera / capture source the user can enable; each becomes a subfolder of `Footage`.
/// Presets are built-in; `custom(_:)` wraps a user-typed name (Lumix, Blackmagic, …).
nonisolated struct FootageSource: Identifiable, Hashable {
    let name: String
    let symbol: String
    let isCustom: Bool

    var id: String { name }
    var folderName: String { name }
}

extension FootageSource {
    static let camA             = FootageSource(name: "Cam A", symbol: "camera", isCustom: false)
    static let camB             = FootageSource(name: "Cam B", symbol: "camera", isCustom: false)
    static let drone            = FootageSource(name: "Drone", symbol: "airplane", isCustom: false)
    static let screenRecordings = FootageSource(name: "Screen Recordings", symbol: "rectangle.dashed.badge.record", isCustom: false)
    static let goPro            = FootageSource(name: "GoPro", symbol: "video.badge.waveform", isCustom: false)
    static let insta360         = FootageSource(name: "Insta360", symbol: "rotate.3d", isCustom: false)
    static let djiOsmo          = FootageSource(name: "DJI Osmo", symbol: "video.circle", isCustom: false)
    static let sony             = FootageSource(name: "Sony", symbol: "camera.fill", isCustom: false)
    static let iPhone           = FootageSource(name: "iPhone", symbol: "iphone", isCustom: false)
    static let webcam           = FootageSource(name: "Webcam", symbol: "web.camera", isCustom: false)
    static let stockFootage     = FootageSource(name: "Stock Footage", symbol: "shippingbox", isCustom: false)

    static let presets: [FootageSource] = [camA, camB, drone, goPro, insta360, djiOsmo, sony, iPhone,
                                           webcam, screenRecordings, stockFootage]

    static func custom(_ name: String) -> FootageSource {
        FootageSource(name: name, symbol: "camera.aperture", isCustom: true)
    }
}
