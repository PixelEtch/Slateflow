//
//  SlateSelfCheck.swift
//  Slateflow
//
//  Debug-only runnable proof of the non-trivial model logic.
//

import Foundation

#if DEBUG
/// Smallest runnable proof of the non-trivial logic. Called from `SlateflowApp.init` in debug.
@MainActor
func slateSelfCheck() {
    assert(ProjectNaming.folderName(sequence: 1, templateName: "SlateTemplate") == "001 - SlateTemplate")
    assert(ProjectNaming.folderName(sequence: 42, templateName: "X") == "042 - X")
    assert(ProjectNaming.folderName(sequence: 1000, templateName: "X") == "1000 - X")

    // Frame rate - plain rates are 1/Ns; NTSC rates use the SMPTE drop-frame fraction.
    assert(FrameRate.fps25.frameDurationFCPX == "1/25s")
    assert(FrameRate.fps24.frameDurationFCPX == "1/24s")
    assert(FrameRate.fps29_97.frameDurationFCPX == "1001/30000s")
    assert(FrameRate.fps23_98.frameDurationFCPX == "1001/24000s")
    assert(FrameRate.fps59_94.frameDurationFCPX == "1001/60000s")
    var settings29_97 = FCPLibrarySettings()
    settings29_97.frameRate = .fps29_97
    assert(settings29_97.frameRate.frameDurationFCPX == "1001/30000s")

    assert(VideoFormat.uhd4k.aspectRatio == "16:9")
    assert(VideoFormat.uhd8k.width == 7680 && VideoFormat.uhd8k.height == 4320)
    assert(VideoFormat.custom(width: 2000, height: 1000).aspectRatio == "2:1")
    assert(VideoFormat(width: 0, height: 0).aspectRatio == "-")
    assert(ResolutionChoice.allCases.count == 5)

    // Aspect-ratio transforms - tier (shorter edge) preserved, other edge derived.
    assert(AspectRatio.wide169.apply(to: .hd1080) == .hd1080)
    assert(AspectRatio.wide169.apply(to: .uhd4k) == .uhd4k)
    assert(AspectRatio.wide169.apply(to: .k2).pixelDimensions == "1920 × 1080")   // 16:9 of the 1080 tier, not DCI 2048
    assert(AspectRatio.square11.apply(to: .uhd4k).pixelDimensions == "2160 × 2160")
    assert(AspectRatio.social45.apply(to: .hd1080).pixelDimensions == "1080 × 1350")
    assert(AspectRatio.classic34.apply(to: .hd1080).pixelDimensions == "1080 × 1440")
    assert(AspectRatio.vertical916.apply(to: .hd1080).pixelDimensions == "1080 × 1920")
    assert(AspectRatio.vertical916.apply(to: .uhd4k).pixelDimensions == "2160 × 3840")
    assert(AspectRatio.vertical916.apply(to: .uhd8k).aspectRatio == "9:16")
    assert(AspectRatio.vertical921.apply(to: .uhd4k).pixelDimensions == "2160 × 5040")
    assert(AspectRatio.ultrawide219.apply(to: .uhd4k).pixelDimensions == "5040 × 2160")

    // Orientation groups its ratios; the store snaps a stale ratio back in range.
    assert(Orientation.landscape.ratios.contains(.wide169))
    assert(Orientation.vertical.ratios.allSatisfy { $0.ratio.w < $0.ratio.h })
    let osc = SlateStore(defaults: UserDefaults(suiteName: "SlateflowSelfCheck-\(UUID().uuidString)")!)
    osc.aspect = .cinema239                 // landscape ratio
    osc.orientation = .vertical             // should force aspect back into the vertical set
    assert(Orientation.vertical.ratios.contains(osc.aspect))

    // Build Archives round-trip: a record captures enough to restore format,
    // naming, and leave-in-place - not roles/collections/footage specifics.
    let sourceStore = SlateStore(defaults: UserDefaults(suiteName: "SlateflowSelfCheck-\(UUID().uuidString)")!)
    sourceStore.choice = .uhd4k
    sourceStore.orientation = .vertical
    sourceStore.aspect = .vertical921
    sourceStore.fcp.frameRate = .fps29_97
    sourceStore.fcp.keepMediaInPlace = false
    sourceStore.templateName = "Commercial"
    assert(sourceStore.rootFolderName == "NNN - Commercial")   // number unknown until build
    let snapshot = BuildRecord(store: sourceStore, rootFolder: sourceStore.rootFolderName(sequence: 1))
    assert(snapshot.rootFolder == "001 - Commercial")

    let destStore = SlateStore(defaults: UserDefaults(suiteName: "SlateflowSelfCheck-\(UUID().uuidString)")!)
    destStore.applyConfiguration(from: snapshot)
    assert(destStore.choice == .uhd4k)
    assert(destStore.orientation == .vertical)
    assert(destStore.aspect == .vertical921)
    assert(destStore.fcp.frameRate == .fps29_97)
    assert(destStore.fcp.keepMediaInPlace == false)
    assert(destStore.templateName == "Commercial")

    // Custom resolution restores exact width/height, not orientation/aspect.
    let customSource = SlateStore(defaults: UserDefaults(suiteName: "SlateflowSelfCheck-\(UUID().uuidString)")!)
    customSource.choice = .custom
    customSource.customWidth = 1000
    customSource.customHeight = 500
    let customSnapshot = BuildRecord(store: customSource, rootFolder: customSource.rootFolderName(sequence: 1))
    let customDest = SlateStore(defaults: UserDefaults(suiteName: "SlateflowSelfCheck-\(UUID().uuidString)")!)
    customDest.applyConfiguration(from: customSnapshot)
    assert(customDest.choice == .custom)
    assert(customDest.customWidth == 1000 && customDest.customHeight == 500)

    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }
    try? DirectoryNode(name: "007 - Old").write(into: tmp)
    try? DirectoryNode(name: "notes").write(into: tmp)                 // ignored: no "NNN - " prefix
    assert(ProjectNaming.nextSequence(in: tmp) == 8)

    // Default Smart Collections have unique names (no duplicate "Footage")
    let names = FCPLibrarySettings().smartCollections.map(\.name)
    assert(names.count == Set(names).count, "duplicate default Smart Collection: \(names)")

    // Preview enrichment never touches the real (write()-tested) tree shape below,
    // and only adds the library row when the app actually ships a template.
    let previewOn = DirectoryNode.previewTemplate(root: "R", keepMediaInPlace: true)
        .children.first { $0.name == "FCP" }!
    let previewOff = DirectoryNode.previewTemplate(root: "R", keepMediaInPlace: false)
        .children.first { $0.name == "FCP" }!
    assert(previewOn.children.contains { $0.name == "Import Settings.md" })
    assert(!previewOff.children.contains { $0.name == "Import Settings.md" })

    // Directory tree - fixed Admin subfolders + only the selected Footage sources
    let sources: [FootageSource] = [.camA, .drone, .stockFootage]
    let tree = DirectoryNode.slateTemplate(root: "001 - SlateTemplate", footageSources: sources)
    let expectedTree: Set<String> = [
        "001 - SlateTemplate",
        "001 - SlateTemplate/Admin",
        "001 - SlateTemplate/Admin/Scripts",
        "001 - SlateTemplate/Admin/NDAs",
        "001 - SlateTemplate/Admin/Fonts",
        "001 - SlateTemplate/Admin/Guidelines",
        "001 - SlateTemplate/Audio",
        "001 - SlateTemplate/Audio/Dialogue",
        "001 - SlateTemplate/Audio/Music",
        "001 - SlateTemplate/Audio/Sound Effects",
        "001 - SlateTemplate/Backup",
        "001 - SlateTemplate/FCP",
        "001 - SlateTemplate/Final Exports",
        "001 - SlateTemplate/Footage",
        "001 - SlateTemplate/Footage/Cam A",
        "001 - SlateTemplate/Footage/Drone",
        "001 - SlateTemplate/Footage/Stock Footage",
        "001 - SlateTemplate/Graphics",
        "001 - SlateTemplate/Images",
    ]
    assert(Set(tree.paths()) == expectedTree,
           "tree mismatch: \(Set(tree.paths()).symmetricDifference(expectedTree))")

    // Footage children follow the given list order
    let footage = tree.children.first { $0.name == "Footage" }!
    assert(footage.children.map(\.name) == ["Cam A", "Drone", "Stock Footage"])
    // Empty selection → Footage is a leaf
    assert(DirectoryNode.slateTemplate(root: "R").children.first { $0.name == "Footage" }!.children.isEmpty)

    let buildTmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: buildTmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: buildTmp) }
    try? tree.write(into: buildTmp)
    for rel in expectedTree {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: buildTmp.appendingPathComponent(rel).path, isDirectory: &isDir)
        assert(exists && isDir.boolValue, "not created on disk: \(rel)")
    }
    // Unselected source must NOT be created
    var goProDir: ObjCBool = false
    assert(!FileManager.default.fileExists(
        atPath: buildTmp.appendingPathComponent("001 - SlateTemplate/Footage/GoPro").path,
        isDirectory: &goProDir))

    // FCPXML: format/project carry resolution + aspect; roles + smart collections
    let vertical4k = AspectRatio.vertical916.apply(to: .uhd4k)
    let xml = FCPXML.document(settings: FCPLibrarySettings(), format: vertical4k,
                              eventName: "001 - SlateTemplate")
    assert(xml.contains("<!DOCTYPE fcpxml>"))
    assert(xml.contains(#"<fcpxml version="1.11">"#))
    assert(xml.contains(#"<format id="r1" name="Slate 2160×3840" width="2160" height="3840" frameDuration="1/25s" colorSpace="1-1-1 (Rec. 709)"/>"#))
    assert(xml.contains(#"<sequence format="r1" duration="0s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">"#))
    assert(xml.contains(#"<project name="001 - SlateTemplate">"#))
    assert(xml.contains("<spine/>"))
    assert(xml.contains(#"<event name="001 - SlateTemplate">"#))
    assert(xml.contains(#"<match-roles rule="includesAny">"#))
    assert(xml.contains(#"<role name="Dialogue"/>"#))
    assert(xml.contains(#"<match-media rule="is" type="stills"/>"#))

    // FCPXML: multi-rule collections for asset filtering
    var custom = FCPLibrarySettings()
    custom.smartCollections = [
        SmartCollectionSpec(name: "Screen Recordings",
                            rules: [.mediaType("videoOnly"), .text("Screen Recording")]),
        SmartCollectionSpec(name: "Cam A", rules: [.property(key: "cameraAngle", value: "Cam A")]),
        SmartCollectionSpec(name: "Day 01", rules: [.keywords(["Day 01"])]),
    ]
    let cx = FCPXML.document(settings: custom, format: .hd1080, eventName: "E")
    assert(cx.contains(#"<smart-collection name="Screen Recordings" match="all">"#))
    assert(cx.contains(#"<match-text rule="includes" value="Screen Recording"/>"#))
    assert(cx.contains(#"<match-property key="cameraAngle" type="string" value="Cam A" rule="is" enabled="1"/>"#))
    assert(cx.contains(#"<match-keywords rule="includesAny">"#))
    assert(cx.contains(#"<keyword-name value="Day 01"/>"#))

    // Footage Source ↔ Smart Collection linkage.
    // Ephemeral defaults so the self-check never touches the user's persisted config.
    let scratchSuite = "SlateflowSelfCheck-\(UUID().uuidString)"
    let scratchDefaults = UserDefaults(suiteName: scratchSuite)!
    defer { scratchDefaults.removePersistentDomain(forName: scratchSuite) }
    let store = SlateStore(defaults: scratchDefaults)
    assert(store.fcp.smartCollections.contains { $0.name == "Cam A" && $0.isFootageLinked },
           "default footage source did not seed its linked collection")
    store.setFootageSource(.drone, enabled: true)
    assert(store.fcp.smartCollections.contains { $0.name == "Drone" && $0.isFootageLinked })
    store.setFootageSource(.drone, enabled: false)
    assert(!store.fcp.smartCollections.contains { $0.name == "Drone" }, "linked collection not removed")
    // A manually-added collection of the same name is left alone by a source toggle.
    store.addQuickCollection(.keyword, value: "GoPro")      // manual, not linked
    store.setFootageSource(.goPro, enabled: true)           // linked add skipped - name taken
    store.setFootageSource(.goPro, enabled: false)          // removes linked only - none
    assert(store.fcp.smartCollections.contains { $0.name == "GoPro" && !$0.isFootageLinked })

    // Custom footage source (Lumix, Blackmagic, …)
    store.addCustomFootageSource("Lumix")
    assert(store.orderedFootageSources.contains { $0.folderName == "Lumix" && $0.isCustom })
    assert(store.fcp.smartCollections.contains { $0.name == "Lumix" && $0.isFootageLinked })
    let before = store.orderedFootageSources.count
    store.addCustomFootageSource("  lumix ")                // case-insensitive duplicate → no-op
    assert(store.orderedFootageSources.count == before, "duplicate custom source added")
    let lumix = store.orderedFootageSources.first { $0.folderName == "Lumix" }!
    store.setFootageSource(lumix, enabled: false)
    assert(!store.orderedFootageSources.contains { $0.folderName == "Lumix" })
    assert(!store.fcp.smartCollections.contains { $0.name == "Lumix" })

    // Typing a preset's name enables the preset, not a custom duplicate.
    store.addCustomFootageSource("insta360")
    assert(store.footageSources.contains(.insta360) && !store.footageSources.contains { $0.isCustom })
    store.setFootageSource(.insta360, enabled: false)

    // Path-traversal sanitisation
    let evil = SafeName.component("../../etc/passwd", fallback: "X")
    assert(!evil.contains("/") && !evil.contains("\\") && !evil.hasPrefix("."))
    assert(SafeName.component("..", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component("...", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component("A/B:C\\D", fallback: "X") == "A-B-C-D")
    assert(SafeName.component("   ", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component(String(repeating: "z", count: 500), fallback: "X").count <= 200)

    let escaper = SlateStore(defaults: scratchDefaults)
    escaper.templateName = "../../../tmp/pwn"
    assert(!escaper.rootFolderName.contains("..") && !escaper.rootFolderName.contains("/"))
    escaper.addCustomFootageSource("../evil")
    assert(!escaper.orderedFootageSources.contains { $0.folderName.contains("/") })

    // Destination-containment guard
    let dst = URL(fileURLWithPath: NSTemporaryDirectory())
    assert(dst.appendingPathComponent("001 - X").isContained(in: dst))
    assert(!dst.appendingPathComponent("../../X").isContained(in: dst))

    // FCPXML library location - points FCP's New Library panel at <root>/FCP.
    let located = FCPXML.document(settings: FCPLibrarySettings(), format: .hd1080, eventName: "E",
                                  libraryLocation: URL(fileURLWithPath: "/tmp/A & B/E.fcpbundle", isDirectory: true))
    assert(located.contains(#"<library location="file:///tmp/A%20&amp;%20B/E.fcpbundle/">"#))
    assert(FCPXML.document(settings: FCPLibrarySettings(), format: .hd1080, eventName: "E").contains("<library>"))
}
#endif
