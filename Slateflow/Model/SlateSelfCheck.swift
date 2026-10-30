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
        format: .hd1080, reelFormat: nil, fcp: FCPLibrarySettings(), footageSources: [.camA], folders: ProjectLayout.defaultFolders)
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
    // Custom sizes below the floor are clamped and flagged, not built as a sliver.
    assert(VideoFormat.custom(width: 3, height: 2160).width == VideoFormat.minimumSide)
    var tiny = SavedSettings()
    tiny.choice = .custom
    tiny.customWidth = 3
    assert(tiny.customDimensionsIssue == .tooSmall, "sub-minimum width not flagged")
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

    // Orientation groups its ratios; Saved Settings snaps a stale ratio back in range.
    assert(Orientation.landscape.ratios.contains(.wide169))
    assert(Orientation.vertical.ratios.allSatisfy { $0.ratio.w < $0.ratio.h })
    var osc = SavedSettings()
    osc.aspect = .cinema239                 // landscape ratio
    osc.orientation = .vertical             // should force aspect back into the vertical set
    assert(Orientation.vertical.ratios.contains(osc.aspect))

    // A saved non-landscape orientation must not snap the saved aspect on restore.
    let orientDefaults = scratch()
    let orientSaver = SlateStore(defaults: orientDefaults, history: scratchHistory())
    orientSaver.settings.orientation = .vertical
    orientSaver.settings.aspect = .vertical921
    let orientReopened = SlateStore(defaults: orientDefaults, history: scratchHistory())
    assert(orientReopened.settings.orientation == .vertical, "orientation not restored")
    assert(orientReopened.settings.aspect == .vertical921, "aspect snapped to default on restore")

    // Building a store writes nothing - not even the defaults or linked collections.
    let untouchedDefaults = scratch()
    _ = SlateStore(defaults: untouchedDefaults, history: scratchHistory())
    assert(untouchedDefaults.persistentDomain(forName: scratchSuites.last!)?.isEmpty ?? true,
           "constructing a store wrote to defaults")

    // The build destination is remembered across launches.
    let destDefaults = scratch()
    let destFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: destFolder) }
    SlateStore(defaults: destDefaults, history: scratchHistory()).setDestination(destFolder)
    assert(SlateStore(defaults: destDefaults, history: scratchHistory()).destination?.standardizedFileURL.path
           == destFolder.standardizedFileURL.path, "destination not remembered")

    // Every persisted field round-trips through a fresh store on the same defaults.
    let roundTripDefaults = scratch()
    let saver = SlateStore(defaults: roundTripDefaults, history: scratchHistory())
    saver.settings.choice = .custom
    saver.settings.orientation = .portrait
    saver.settings.aspect = .classic34
    saver.settings.customWidth = 1234
    saver.settings.customHeight = 5678
    saver.settings.templateName = "Round Trip"
    saver.settings.fcp.frameRate = .fps59_94
    saver.settings.fcp.keepMediaInPlace = false
    saver.settings.fcp.colorSpace = .pq
    saver.settings.fcp.reelTimeline = true
    saver.settings.setFootageSource(.camB, enabled: false)
    saver.settings.addCustomFootageSource("Lumix")
    saver.settings.fcp.addRole("Interview", to: \.videoRoles)
    saver.settings.fcp.addRole("Ambience", to: \.audioRoles)
    saver.settings.fcp.addCollection(.keyword, value: "Day 01")
    saver.settings.addFolder("Admin/Contracts")
    saver.settings.removeFolder("Images")
    if let i = saver.settings.fcp.smartCollections.firstIndex(where: { $0.name == "Day 01" }) {
        saver.settings.fcp.smartCollections[i].enabled = false
    }
    let loaded = SlateStore(defaults: roundTripDefaults, history: scratchHistory())
    assert(loaded.settings.choice == .custom, "choice not restored")
    assert(loaded.settings.orientation == .portrait, "orientation not restored")
    assert(loaded.settings.aspect == .classic34, "aspect not restored")
    assert(loaded.settings.customWidth == 1234 && loaded.settings.customHeight == 5678, "custom size not restored")
    assert(loaded.settings.templateName == "Round Trip", "template name not restored")
    assert(loaded.settings.fcp.frameRate == .fps59_94, "frame rate not restored")
    assert(loaded.settings.fcp.keepMediaInPlace == false, "leave-in-place not restored")
    assert(loaded.settings.fcp.colorSpace == .pq && loaded.settings.fcp.reelTimeline, "color space / reel timeline not restored")
    assert(loaded.settings.footageSources == [.camA, .custom("Lumix")], "footage sources not restored")
    assert(loaded.settings.fcp.videoRoles == saver.settings.fcp.videoRoles && loaded.settings.fcp.videoRoles.contains("Interview"))
    assert(loaded.settings.fcp.audioRoles == saver.settings.fcp.audioRoles && loaded.settings.fcp.audioRoles.contains("Ambience"))
    assert(loaded.settings.fcp.smartCollections == saver.settings.fcp.smartCollections, "collections not restored")
    assert(loaded.settings.folders == saver.settings.folders && loaded.settings.folders.contains("Admin/Contracts")
           && !loaded.settings.folders.contains("Images"), "folders not restored")
    assert(loaded.settings.fcp.smartCollections.contains { $0.name == "Day 01" && !$0.enabled }, "enabled not restored")

    // Build Archives round-trip: a record captures enough to restore format,
    // naming, and leave-in-place - not roles/collections/footage specifics.
    var source = SavedSettings()
    source.choice = .uhd4k
    source.orientation = .vertical
    source.aspect = .vertical921
    source.fcp.frameRate = .fps29_97
    source.fcp.keepMediaInPlace = false
    source.templateName = "Commercial"
    assert(source.rootFolderName == "NNN - Commercial")   // number unknown until build
    let snapshot = BuildRecord(snapshot: source.snapshot,
                               rootFolder: ProjectLayout.rootName(sequence: 1000, template: source.safeTemplateName))
    assert(snapshot.rootFolder == "1000 - Commercial")

    var dest = SavedSettings()
    dest.applyConfiguration(from: snapshot)
    assert(dest.choice == .uhd4k)
    assert(dest.orientation == .vertical)
    assert(dest.aspect == .vertical921)
    assert(dest.fcp.frameRate == .fps29_97)
    assert(dest.fcp.keepMediaInPlace == false)
    assert(dest.templateName == "Commercial")

    // Custom resolution restores exact width/height, not orientation/aspect.
    var customSource = SavedSettings()
    customSource.choice = .custom
    customSource.customWidth = 1000
    customSource.customHeight = 500
    let customSnapshot = BuildRecord(snapshot: customSource.snapshot, rootFolder: "001 - X")
    var customDest = SavedSettings()
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

    // FCP/ holds only the project file; the manifest is a hidden file at the root.
    let planFCP = ProjectLayout.plan(root: "R", folders: ProjectLayout.defaultFolders, footageSources: []).children.first { $0.name == "FCP" }!
    assert(planFCP.children.map(\.name) == ["R.fcpxml"], "FCP folder: \(planFCP.children.map(\.name))")

    // Directory tree - fixed Admin subfolders + only the selected Footage sources
    let sources: [FootageSource] = [.camA, .drone, .stockFootage]
    let tree = ProjectLayout.plan(root: "001 - SlateTemplate", folders: ProjectLayout.defaultFolders, footageSources: sources)
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
        "001 - SlateTemplate/Final Exports",
        "001 - SlateTemplate/Footage",
        "001 - SlateTemplate/Footage/Cam A",
        "001 - SlateTemplate/Footage/Drone",
        "001 - SlateTemplate/Footage/Stock Footage",
        "001 - SlateTemplate/Graphics",
        "001 - SlateTemplate/Images",
        "001 - SlateTemplate/.slateflow.json",
    ]
    assert(Set(tree.paths()) == expectedTree,
           "tree mismatch: \(Set(tree.paths()).symmetricDifference(expectedTree))")

    // Footage children follow the given list order
    let footage = tree.children.first { $0.name == "Footage" }!
    assert(footage.children.map(\.name) == ["Cam A", "Drone", "Stock Footage"])

    // Editable folders: sanitised, no duplicates, never inside a folder Slateflow owns.
    var folderRules = SavedSettings()
    folderRules.addFolder(" Admin / Contracts ")
    folderRules.addFolder("admin/contracts")                 // same folder, other case → no-op
    folderRules.addFolder("Admin")                           // already a parent → no-op
    folderRules.addFolder("Footage/Extra")                   // owned by Footage Sources
    folderRules.addFolder("fcp")
    folderRules.addFolder("../../etc")
    folderRules.addFolder(" / ")
    assert(folderRules.folders == ProjectLayout.defaultFolders + ["Admin/Contracts", "etc"],
           "folder rules: \(folderRules.folders)")
    assert(!folderRules.folders.contains { $0.contains("..") })
    folderRules.removeFolder("Admin/Contracts")
    folderRules.resetFolders()
    assert(folderRules.folders == ProjectLayout.defaultFolders)

    // Custom folders shape the plan; the same name under two parents stays two rows.
    let customTree = ProjectLayout.plan(root: "R", folders: ["Zeta", "Audio/Music", "Graphics/Music", "Admin"],
                                        footageSources: [])
    assert(customTree.children.map(\.name) == ["Admin", "Audio", "Backup", "FCP", "Footage", "Graphics", "Zeta",
                                               ".slateflow.json"], "custom top level: \(customTree.children.map(\.name))")
    let ids = customTree.paths()
    assert(ids.contains("R/Audio/Music") && ids.contains("R/Graphics/Music"))
    func allIDs(_ n: DirectoryNode) -> [String] { [n.id] + n.children.flatMap(allIDs) }
    assert(Set(allIDs(customTree)).count == allIDs(customTree).count, "duplicate row ids in the Folder Preview")
    // Empty selection → Footage is a leaf
    assert(ProjectLayout.plan(root: "R", folders: ProjectLayout.defaultFolders, footageSources: [])
        .children.first { $0.name == "Footage" }!.children.isEmpty)

    // End-to-end build into a temp folder: every planned folder and file exists,
    // and nothing else - the preview is exactly what gets written.
    let buildTmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: buildTmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: buildTmp) }
    let buildSnapshot = BuildSnapshot(
        templateName: "SlateTemplate", choice: .uhd4k, orientation: .landscape, aspect: .wide169,
        format: .uhd4k, reelFormat: nil, fcp: FCPLibrarySettings(), footageSources: sources, folders: ProjectLayout.defaultFolders)
    let built = try! ProjectLayout.build(buildSnapshot, in: buildTmp)
    assert(built.lastPathComponent == "001 - SlateTemplate")
    let planned = ProjectLayout.plan(root: "001 - SlateTemplate", folders: ProjectLayout.defaultFolders, footageSources: sources)
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
        aspect: .wide169, format: .uhd4k, reelFormat: nil, fcp: FCPLibrarySettings(), footageSources: [], folders: ProjectLayout.defaultFolders)
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
    var linked = SavedSettings()
    assert(linked.fcp.smartCollections.contains { $0.name == "Cam A" && $0.isFootageLinked },
           "default footage source did not seed its linked collection")
    linked.setFootageSource(.drone, enabled: true)
    assert(linked.fcp.smartCollections.contains { $0.name == "Drone" && $0.isFootageLinked })
    linked.setFootageSource(.drone, enabled: false)
    assert(!linked.fcp.smartCollections.contains { $0.name == "Drone" }, "linked collection not removed")
    // A manually-added collection of the same name is left alone by a source toggle.
    linked.fcp.addCollection(.keyword, value: "GoPro")      // manual, not linked
    linked.setFootageSource(.goPro, enabled: true)           // linked add skipped - name taken
    linked.setFootageSource(.goPro, enabled: false)          // removes linked only - none
    assert(linked.fcp.smartCollections.contains { $0.name == "GoPro" && !$0.isFootageLinked })

    // Custom role: added to its list once, with a matching role collection.
    linked.fcp.addRole(" B-Roll ", to: \.videoRoles)
    linked.fcp.addRole("B-Roll", to: \.videoRoles)          // duplicate → no-op
    assert(linked.fcp.videoRoles.filter { $0 == "B-Roll" }.count == 1 && !linked.fcp.audioRoles.contains("B-Roll"))
    assert(linked.fcp.smartCollections.contains { $0.name == "B-Roll" && $0.rules == [.role("B-Roll")] })

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

    // Sources, roles and collections persist: a fresh linked on the same defaults
    // restores exactly what was saved.
    linked.setFootageSource(.drone, enabled: true)
    let scratchDefaults = scratch()
    SlateStore(defaults: scratchDefaults, history: scratchHistory()).settings = linked
    let reopened = SlateStore(defaults: scratchDefaults, history: scratchHistory())
    assert(reopened.settings.footageSources == linked.footageSources, "footage sources not restored")
    assert(reopened.settings.fcp.videoRoles == linked.fcp.videoRoles, "roles not restored")
    assert(reopened.settings.fcp.smartCollections == linked.fcp.smartCollections, "collections not restored")
    linked.setFootageSource(.drone, enabled: false)

    // Custom footage source (Lumix, Blackmagic, …)
    linked.addCustomFootageSource("Lumix")
    assert(linked.orderedFootageSources.contains { $0.folderName == "Lumix" && $0.isCustom })
    assert(linked.fcp.smartCollections.contains { $0.name == "Lumix" && $0.isFootageLinked })
    let before = linked.orderedFootageSources.count
    linked.addCustomFootageSource("  lumix ")                // case-insensitive duplicate → no-op
    assert(linked.orderedFootageSources.count == before, "duplicate custom source added")
    let lumix = linked.orderedFootageSources.first { $0.folderName == "Lumix" }!
    linked.setFootageSource(lumix, enabled: false)
    assert(!linked.orderedFootageSources.contains { $0.folderName == "Lumix" })
    assert(!linked.fcp.smartCollections.contains { $0.name == "Lumix" })

    // Typing a preset's name enables the preset, not a custom duplicate.
    linked.addCustomFootageSource("insta360")
    assert(linked.footageSources.contains(.insta360) && !linked.footageSources.contains { $0.isCustom })
    linked.setFootageSource(.insta360, enabled: false)

    // Path-traversal sanitisation
    let evil = SafeName.component("../../etc/passwd", fallback: "X")
    assert(!evil.contains("/") && !evil.contains("\\") && !evil.hasPrefix("."))
    assert(SafeName.component("..", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component("...", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component("A/B:C\\D", fallback: "X") == "A-B-C-D")
    assert(SafeName.component("   ", fallback: "SlateTemplate") == "SlateTemplate")
    assert(SafeName.component(String(repeating: "z", count: 500), fallback: "X").count <= 200)

    var escaper = SavedSettings()
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
    assert(unlocated.contains(#"colorSpace="1-1-1 (Rec. 709)""#) && !unlocated.contains("<project name=\"E Reel\">"))

    // Reel timeline: a 9:16 sibling of a preset landscape or portrait project, never of a
    // vertical or custom one.
    var reel = SavedSettings()
    reel.choice = .uhd4k
    reel.orientation = .landscape
    assert(reel.reelFormat == nil, "reel timeline built while off")
    reel.fcp.reelTimeline = true
    assert(reel.reelFormat == VideoFormat(width: 2160, height: 3840), "reel size: \(String(describing: reel.reelFormat))")
    reel.orientation = .vertical
    assert(reel.reelFormat == nil && !reel.canAddReelTimeline, "reel timeline on a vertical project")
    reel.orientation = .landscape
    reel.choice = .custom
    assert(reel.reelFormat == nil, "reel timeline on a custom size")

    // HLG + reel: a wide-gamut HDR library, HLG formats, and a second project on r2.
    var hdrSettings = FCPLibrarySettings()
    hdrSettings.colorSpace = .hlg
    let hdrDoc = FCPXML.document(settings: hdrSettings, format: .uhd4k,
                                 reelFormat: VideoFormat(width: 2160, height: 3840), eventName: "E")
    assert(hdrDoc.contains(#"<library colorProcessing="wide-hdr">"#), "HDR library missing")
    assert(hdrDoc.contains(#"<format id="r2" name="Slate 2160×3840" width="2160" height="3840""#))
    assert(!hdrDoc.contains("Rec. 709") && hdrDoc.contains(#"colorSpace="9-18-9 (Rec. 2020 HLG)""#))
    assert(hdrDoc.contains("<project name=\"E Reel\">\n<sequence format=\"r2\""), "reel project missing")
    // Each color space sets its library processing to match.
    for (space, library) in [(ColorSpace.rec709, "<library>"), (.rec2020, #"<library colorProcessing="wide">"#),
                             (.pq, #"<library colorProcessing="wide-hdr">"#)] {
        var settings = FCPLibrarySettings()
        settings.colorSpace = space
        let doc = FCPXML.document(settings: settings, format: .hd1080, eventName: "E")
        assert(doc.contains(library) && doc.contains(#"colorSpace="\#(space.fcpxmlValue)""#), "color space \(space)")
    }
}
#endif
