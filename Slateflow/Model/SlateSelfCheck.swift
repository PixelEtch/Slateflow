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
    // Ephemeral defaults so the self-check never touches the user's persisted config;
    // every suite it creates is removed on the way out.
    var scratchSuites: [String] = []
    defer { for name in scratchSuites { UserDefaults.standard.removePersistentDomain(forName: name) } }
    func scratch() -> UserDefaults {
        let name = "SlateflowSelfCheck-\(UUID().uuidString)"
        scratchSuites.append(name)
        return UserDefaults(suiteName: name)!
    }
    // Throwaway Build Archives files, so no store here reads or writes the user's archive.
    let archiveTmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: archiveTmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: archiveTmp) }
    func scratchHistory() -> SelectionHistory {
        SelectionHistory(fileURL: archiveTmp.appendingPathComponent("\(UUID().uuidString).json"))
    }

    // Build Archives: records persist, export/import round-trips, importing twice adds nothing.
    let archiveSnapshot = BuildSnapshot(
        templateName: "A", choice: .hd1080, orientation: .landscape, aspect: .wide169,
        format: .hd1080, fcp: FCPLibrarySettings(), footageSources: [.camA])
    let archive = scratchHistory()
    archive.record(BuildRecord(snapshot: archiveSnapshot, rootFolder: "001 - A"))
    archive.record(BuildRecord(snapshot: archiveSnapshot, rootFolder: "002 - A"))
    assert(SelectionHistory(fileURL: archive.fileURL).builds.map(\.rootFolder) == ["001 - A", "002 - A"],
           "Build Archives not restored from disk")
    let exported = archiveTmp.appendingPathComponent("export.json")
    try! archive.exportBackup(to: exported)
    let restored = scratchHistory()
    try! restored.importBackup(from: exported)
    try! restored.importBackup(from: exported)
    assert(restored.builds.map(\.id) == archive.builds.map(\.id), "import lost or duplicated records")
    restored.remove(restored.builds[0])
    assert(SelectionHistory(fileURL: restored.fileURL).builds.map(\.rootFolder) == ["002 - A"])
    restored.clear()
    assert(SelectionHistory(fileURL: restored.fileURL).builds.isEmpty)

    // An unreadable archive is kept aside, not overwritten by the next build.
    let corrupt = archiveTmp.appendingPathComponent("corrupt.json")
    try! Data("not json".utf8).write(to: corrupt)
    let recovering = SelectionHistory(fileURL: corrupt)
    assert(recovering.builds.isEmpty)
    recovering.record(BuildRecord(snapshot: archiveSnapshot, rootFolder: "003 - A"))
    let kept = try! FileManager.default.contentsOfDirectory(at: archiveTmp, includingPropertiesForKeys: nil)
        .filter { $0.lastPathComponent.hasPrefix("corrupt.unreadable-") }
    assert(kept.count == 1 && (try? Data(contentsOf: kept[0])) == Data("not json".utf8),
           "unreadable Build Archives file was overwritten")

    assert(ProjectLayout.rootName(sequence: 1, template: "SlateTemplate") == "001 - SlateTemplate")
    assert(ProjectLayout.rootName(sequence: 42, template: "X") == "042 - X")
    assert(ProjectLayout.rootName(sequence: 1000, template: "X") == "1000 - X")
    // Parsing round-trips past 999 and keeps " - " inside the template name.
    assert(ProjectLayout.parse(rootName: "1000 - X")! == (1000, "X"))
    assert(ProjectLayout.parse(rootName: "007 - A - B")! == (7, "A - B"))
    assert(ProjectLayout.parse(rootName: "notes") == nil)
    assert(ProjectLayout.parse(rootName: "12 - X") == nil)
    assert(ProjectLayout.parse(rootName: "001 -X") == nil)

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
    let osc = SlateStore(defaults: scratch(), history: scratchHistory())
    osc.aspect = .cinema239                 // landscape ratio
    osc.orientation = .vertical             // should force aspect back into the vertical set
    assert(Orientation.vertical.ratios.contains(osc.aspect))

    // A saved non-landscape orientation must not snap the saved aspect on restore.
    let orientDefaults = scratch()
    let orientSaver = SlateStore(defaults: orientDefaults, history: scratchHistory())
    orientSaver.orientation = .vertical
    orientSaver.aspect = .vertical921
    let orientReopened = SlateStore(defaults: orientDefaults, history: scratchHistory())
    assert(orientReopened.orientation == .vertical, "orientation not restored")
    assert(orientReopened.aspect == .vertical921, "aspect snapped to default on restore")

    // Building a store writes nothing - not even the defaults or linked collections.
    let untouchedDefaults = scratch()
    _ = SlateStore(defaults: untouchedDefaults, history: scratchHistory())
    assert(untouchedDefaults.persistentDomain(forName: scratchSuites.last!)?.isEmpty ?? true,
           "constructing a store wrote to defaults")

    // Every persisted field round-trips through a fresh store on the same defaults.
    let roundTripDefaults = scratch()
    let saver = SlateStore(defaults: roundTripDefaults, history: scratchHistory())
    saver.choice = .custom
    saver.orientation = .portrait
    saver.aspect = .classic34
    saver.customWidth = 1234
    saver.customHeight = 5678
    saver.templateName = "Round Trip"
    saver.fcp.frameRate = .fps59_94
    saver.fcp.keepMediaInPlace = false
    saver.setFootageSource(.camB, enabled: false)
    saver.addCustomFootageSource("Lumix")
    saver.fcp.addRole("Interview", to: \.videoRoles)
    saver.fcp.addRole("Ambience", to: \.audioRoles)
    saver.fcp.addCollection(.keyword, value: "Day 01")
    if let i = saver.fcp.smartCollections.firstIndex(where: { $0.name == "Day 01" }) {
        saver.fcp.smartCollections[i].enabled = false
    }
    let loaded = SlateStore(defaults: roundTripDefaults, history: scratchHistory())
    assert(loaded.choice == .custom, "choice not restored")
    assert(loaded.orientation == .portrait, "orientation not restored")
    assert(loaded.aspect == .classic34, "aspect not restored")
    assert(loaded.customWidth == 1234 && loaded.customHeight == 5678, "custom size not restored")
    assert(loaded.templateName == "Round Trip", "template name not restored")
    assert(loaded.fcp.frameRate == .fps59_94, "frame rate not restored")
    assert(loaded.fcp.keepMediaInPlace == false, "leave-in-place not restored")
    assert(loaded.footageSources == [.camA, .custom("Lumix")], "footage sources not restored")
    assert(loaded.fcp.videoRoles == saver.fcp.videoRoles && loaded.fcp.videoRoles.contains("Interview"))
    assert(loaded.fcp.audioRoles == saver.fcp.audioRoles && loaded.fcp.audioRoles.contains("Ambience"))
    assert(loaded.fcp.smartCollections == saver.fcp.smartCollections, "collections not restored")
    assert(loaded.fcp.smartCollections.contains { $0.name == "Day 01" && !$0.enabled }, "enabled not restored")

    // Build Archives round-trip: a record captures enough to restore format,
    // naming, and leave-in-place - not roles/collections/footage specifics.
    let sourceStore = SlateStore(defaults: scratch(), history: scratchHistory())
    sourceStore.choice = .uhd4k
    sourceStore.orientation = .vertical
    sourceStore.aspect = .vertical921
    sourceStore.fcp.frameRate = .fps29_97
    sourceStore.fcp.keepMediaInPlace = false
    sourceStore.templateName = "Commercial"
    assert(sourceStore.rootFolderName == "NNN - Commercial")   // number unknown until build
    let snapshot = BuildRecord(snapshot: sourceStore.snapshot,
                               rootFolder: ProjectLayout.rootName(sequence: 1000, template: sourceStore.safeTemplateName))
    assert(snapshot.rootFolder == "1000 - Commercial")

    let destStore = SlateStore(defaults: scratch(), history: scratchHistory())
    destStore.applyConfiguration(from: snapshot)
    assert(destStore.choice == .uhd4k)
    assert(destStore.orientation == .vertical)
    assert(destStore.aspect == .vertical921)
    assert(destStore.fcp.frameRate == .fps29_97)
    assert(destStore.fcp.keepMediaInPlace == false)
    assert(destStore.templateName == "Commercial")

    // Custom resolution restores exact width/height, not orientation/aspect.
    let customSource = SlateStore(defaults: scratch(), history: scratchHistory())
    customSource.choice = .custom
    customSource.customWidth = 1000
    customSource.customHeight = 500
    let customSnapshot = BuildRecord(snapshot: customSource.snapshot, rootFolder: "001 - X")
    let customDest = SlateStore(defaults: scratch(), history: scratchHistory())
    customDest.applyConfiguration(from: customSnapshot)
    assert(customDest.choice == .custom)
    assert(customDest.customWidth == 1000 && customDest.customHeight == 500)

    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }
    try? DirectoryNode(name: "007 - Old").write(into: tmp)
    try? DirectoryNode(name: "notes").write(into: tmp)                 // ignored: no "NNN - " prefix
    assert(ProjectLayout.nextSequence(in: tmp) == 8)
    try? DirectoryNode(name: "999 - Big").write(into: tmp)
    assert(ProjectLayout.nextSequence(in: tmp) == 1000)
    try? DirectoryNode(name: "1000 - Bigger").write(into: tmp)
    assert(ProjectLayout.nextSequence(in: tmp) == 1001, "numbering stalls past 999")

    // Default Smart Collections have unique names (no duplicate "Footage")
    let names = FCPLibrarySettings().smartCollections.map(\.name)
    assert(names.count == Set(names).count, "duplicate default Smart Collection: \(names)")

    // Preview enrichment never touches the real (write()-tested) tree shape below,
    // and only adds the library row when the app actually ships a template.
    let previewOn = ProjectLayout.plan(root: "R", footageSources: [], keepMediaInPlace: true)
        .children.first { $0.name == "FCP" }!
    let previewOff = ProjectLayout.plan(root: "R", footageSources: [], keepMediaInPlace: false)
        .children.first { $0.name == "FCP" }!
    assert(previewOn.children.contains { $0.name == "Import Settings.md" })
    assert(!previewOff.children.contains { $0.name == "Import Settings.md" })

    // Directory tree - fixed Admin subfolders + only the selected Footage sources
    let sources: [FootageSource] = [.camA, .drone, .stockFootage]
    let tree = ProjectLayout.plan(root: "001 - SlateTemplate", footageSources: sources, keepMediaInPlace: true)
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
        "001 - SlateTemplate/FCP/001 - SlateTemplate.fcpxml",
        "001 - SlateTemplate/FCP/Import Settings.md",
        "001 - SlateTemplate/Final Exports",
        "001 - SlateTemplate/Footage",
        "001 - SlateTemplate/Footage/Cam A",
        "001 - SlateTemplate/Footage/Drone",
        "001 - SlateTemplate/Footage/Stock Footage",
        "001 - SlateTemplate/Graphics",
        "001 - SlateTemplate/Images",
        "001 - SlateTemplate/Slate Project.json",
    ]
    assert(Set(tree.paths()) == expectedTree,
           "tree mismatch: \(Set(tree.paths()).symmetricDifference(expectedTree))")

    // Footage children follow the given list order
    let footage = tree.children.first { $0.name == "Footage" }!
    assert(footage.children.map(\.name) == ["Cam A", "Drone", "Stock Footage"])
    // Empty selection → Footage is a leaf
    assert(ProjectLayout.plan(root: "R", footageSources: [], keepMediaInPlace: true)
        .children.first { $0.name == "Footage" }!.children.isEmpty)

    // End-to-end build into a temp folder: every planned folder and file exists,
    // and nothing else - the preview is exactly what gets written.
    let buildTmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: buildTmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: buildTmp) }
    let buildSnapshot = BuildSnapshot(
        templateName: "SlateTemplate", choice: .uhd4k, orientation: .landscape, aspect: .wide169,
        format: .uhd4k, fcp: FCPLibrarySettings(), footageSources: sources)
    let built = try! ProjectLayout.build(buildSnapshot, in: buildTmp)
    assert(built.lastPathComponent == "001 - SlateTemplate")
    let planned = ProjectLayout.plan(root: "001 - SlateTemplate", footageSources: sources,
                                     keepMediaInPlace: buildSnapshot.fcp.keepMediaInPlace)
    func walk(_ node: DirectoryNode, _ prefix: String) -> [(String, Bool)] {
        let here = prefix.isEmpty ? node.name : "\(prefix)/\(node.name)"
        return [(here, node.isFile)] + node.children.flatMap { walk($0, here) }
    }
    for (rel, isFile) in walk(planned, "") {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: buildTmp.appendingPathComponent(rel).path, isDirectory: &isDir)
        assert(exists && isDir.boolValue != isFile, "not created as planned: \(rel)")
    }
    let onDisk = FileManager.default.enumerator(atPath: buildTmp.path)!.allObjects as! [String]
    assert(Set(onDisk) == Set(planned.paths()),
           "disk differs from plan: \(Set(onDisk).symmetricDifference(Set(planned.paths())))")
    // Unselected source must NOT be created
    assert(!FileManager.default.fileExists(
        atPath: buildTmp.appendingPathComponent("001 - SlateTemplate/Footage/GoPro").path))
    assert(ProjectLayout.fcpxmlURL(root: built).path == built.path + "/FCP/001 - SlateTemplate.fcpxml")
    // Manifest and archive record come from the same snapshot.
    let manifestData = try! Data(contentsOf: built.appendingPathComponent(ProjectLayout.manifestFile))
    let manifestJSON = try! JSONSerialization.jsonObject(with: manifestData) as! [String: Any]
    let builtRecord = BuildRecord(snapshot: buildSnapshot, rootFolder: built.lastPathComponent)
    assert(manifestJSON["template"] as? String == builtRecord.rootFolder)
    assert(manifestJSON["orientation"] as? String == builtRecord.orientation)
    assert(manifestJSON["width"] as? Int == builtRecord.width)
    // The next build takes the next number.
    assert(try! ProjectLayout.build(buildSnapshot, in: buildTmp).lastPathComponent == "002 - SlateTemplate")

    // A failed build removes the folder it created: a 245-character template fits the
    // root folder (251 bytes) but not "<root>.fcpxml" (258 > 255), so the FCPXML write fails.
    let failTmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: failTmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: failTmp) }
    let tooLong = BuildSnapshot(
        templateName: String(repeating: "x", count: 245), choice: .uhd4k, orientation: .landscape,
        aspect: .wide169, format: .uhd4k, fcp: FCPLibrarySettings(), footageSources: [])
    assert((try? ProjectLayout.build(tooLong, in: failTmp)) == nil, "oversized build should fail")
    assert((try? FileManager.default.contentsOfDirectory(atPath: failTmp.path))?.isEmpty == true,
           "failed build left a partial folder")

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
    let scratchDefaults = scratch()
    let store = SlateStore(defaults: scratchDefaults, history: scratchHistory())
    assert(store.fcp.smartCollections.contains { $0.name == "Cam A" && $0.isFootageLinked },
           "default footage source did not seed its linked collection")
    store.setFootageSource(.drone, enabled: true)
    assert(store.fcp.smartCollections.contains { $0.name == "Drone" && $0.isFootageLinked })
    store.setFootageSource(.drone, enabled: false)
    assert(!store.fcp.smartCollections.contains { $0.name == "Drone" }, "linked collection not removed")
    // A manually-added collection of the same name is left alone by a source toggle.
    store.fcp.addCollection(.keyword, value: "GoPro")      // manual, not linked
    store.setFootageSource(.goPro, enabled: true)           // linked add skipped - name taken
    store.setFootageSource(.goPro, enabled: false)          // removes linked only - none
    assert(store.fcp.smartCollections.contains { $0.name == "GoPro" && !$0.isFootageLinked })

    // Custom role: added to its list once, with a matching role collection.
    store.fcp.addRole(" B-Roll ", to: \.videoRoles)
    store.fcp.addRole("B-Roll", to: \.videoRoles)          // duplicate → no-op
    assert(store.fcp.videoRoles.filter { $0 == "B-Roll" }.count == 1 && !store.fcp.audioRoles.contains("B-Roll"))
    assert(store.fcp.smartCollections.contains { $0.name == "B-Roll" && $0.rules == [.role("B-Roll")] })

    // Smart Collection rules: no duplicates by name or by rules; blanks ignored;
    // removing a role collection removes its role.
    var rules = FCPLibrarySettings()
    let startCount = rules.smartCollections.count
    rules.addCollection(.screenRecordings)                       // already a default
    rules.addCollection(SmartCollectionSpec(name: "Screen Recording", rules: SmartCollectionSpec.screenRecordings.rules))
    rules.addCollection(.keyword, value: "   ")
    assert(rules.smartCollections.count == startCount, "duplicate or blank collection added")
    rules.addCollection(.cameraAngle, value: " Cam C ")
    assert(rules.smartCollections.last == SmartCollectionSpec(
        name: "Cam C", rules: [.property(key: SmartCollectionSpec.cameraAngleKey, value: "Cam C")]))
    rules.addRole("Interview", to: \.audioRoles)
    rules.removeCollection(rules.smartCollections.first { $0.name == "Interview" }!)
    assert(!rules.audioRoles.contains("Interview") && !rules.smartCollections.contains { $0.name == "Interview" })

    // Sources, roles and collections persist: a fresh store on the same defaults
    // restores exactly what this one has.
    store.setFootageSource(.drone, enabled: true)
    let reopened = SlateStore(defaults: scratchDefaults, history: scratchHistory())
    assert(reopened.footageSources == store.footageSources, "footage sources not restored")
    assert(reopened.fcp.videoRoles == store.fcp.videoRoles, "roles not restored")
    assert(reopened.fcp.smartCollections == store.fcp.smartCollections, "collections not restored")
    store.setFootageSource(.drone, enabled: false)

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

    let escaper = SlateStore(defaults: scratchDefaults, history: scratchHistory())
    escaper.templateName = "../../../tmp/pwn"
    assert(!escaper.rootFolderName.contains("..") && !escaper.rootFolderName.contains("/"))
    escaper.addCustomFootageSource("../evil")
    assert(!escaper.orderedFootageSources.contains { $0.folderName.contains("/") })

    // Destination-containment guard
    let dst = URL(fileURLWithPath: NSTemporaryDirectory())
    assert(dst.appendingPathComponent("001 - X").isContained(in: dst))
    assert(!dst.appendingPathComponent("../../X").isContained(in: dst))

    // FCPXML library location - the first child of <fcpxml>, so Final Cut creates the
    // library at <root>/FCP/<root>.fcpbundle without asking.
    let located = FCPXML.document(settings: FCPLibrarySettings(), format: .hd1080, eventName: "E",
                                  libraryLocation: URL(fileURLWithPath: "/tmp/A & B/E.fcpbundle", isDirectory: false))
    assert(located.contains(#"<fcpxml version="1.11">\#n<import-options>\#n<option key="library location" value="file:///tmp/A%20&amp;%20B/E.fcpbundle"/>"#),
           "library location import option missing or not first")
    assert(located.contains("<library>\n<event"))
    let unlocated = FCPXML.document(settings: FCPLibrarySettings(), format: .hd1080, eventName: "E")
    assert(!unlocated.contains("import-options") && unlocated.contains("<library>"))
}
#endif
