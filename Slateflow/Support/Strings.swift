//
//  Strings.swift
//  Slateflow
//
//  Every user-facing string in the UI. One place to edit copy.
//

import Foundation

enum Strings {

    enum App {
        static let inspector = "Inspector"
        static let inspectorToggleHelp = "Show or hide the inspector"
    }

    enum Format {
        static let section = "Format"
        static let resolution = "Resolution"
        static let orientation = "Orientation"
        static let dimensions = "Dimensions"
        static let width = "Width"
        static let height = "Height"
        static let frameRate = "Frame rate"
        static let outputSize = "Output size"
        static let aspectRatio = "Aspect ratio"
        static let dimensionSeparator = "×"
        static let dimensionsOdd = "Final Cut needs even dimensions - odd values round down when the project is created."
        static let colorSpace = "Color space"
        static let colorSpaceHelp = "The color space you edit and export in. Footage from any camera is converted to it, and the library is set up to match."
        static let reelTimeline = "Reel timeline"
        static let reelTimelineHelp = "Also adds a 9:16 timeline for reels, next to the main one."
        static let dimensionsTooSmall = "Width and height must be at least \(VideoFormat.minimumSide) px."
    }

    enum ProjectFolder {
        static let section = "Project Folder"
        static let templateName = "Project name"
        static let sequenceNote =
            "The 3-digit prefix is assigned when the project is created, from the numbered "
            + "folders already in the location you pick."
    }

    enum FootageSources {
        static let section = "Cameras"
        static let addLabel = "Other camera"
        static let addPrompt = "Other camera, e.g. Lumix S5"
        static let add = "Add camera"
        static func remove(_ name: String) -> String { "Remove \(name)" }
    }

    enum Folders {
        static let section = "Folders"
        static let addLabel = "New folder"
        static let addPrompt = "New folder, e.g. Admin/Contracts"
        static let add = "Add folder"
        static func remove(_ path: String) -> String { "Remove \(path)" }
        static let reset = "Restore Defaults"
        static let none = "Only Backup, FCP and Footage"
        static let footer = "Use / for a subfolder. Backup, FCP and Footage are always created."
    }

    enum FCP {
        static let leaveFilesInPlace = "Leave files in place"
        static let leaveFilesInPlaceHelp =
            "Media stays in the project’s folders."
        /// Final Cut can't take these from the .fcpxml, so the user sets them once in Final Cut.
        static let finalCutHints =
            "In Final Cut Pro ▸ Settings ▸ Import, turn on Leave files in place and Keywords: From folders. "
            + "When a new library asks for storage locations, set Backups to the project's Backup folder."
    }

    enum SmartCollections {
        static let section = "Smart Collections"
        static let footer =
            "Enabled collections go into the project's .fcpxml and sort clips automatically on import."
        static let add = "Add Collection"
        static let screenRecordings = "Screen Recordings"
        static let byCameraAngle = "By Camera Angle…"
        static let byShootDay = "By Shoot Day…"
        static let byKeyword = "By Keyword…"
        static let videoRole = "Video Role…"
        static let audioRole = "Audio Role…"
        static let remove = "Remove"
        static func remove(_ name: String) -> String { "Remove \(name)" }
        static let fromFootageSources = "from Cameras"

        enum Draft {
            static let cancel = "Cancel"
            static let add = "Add"

            static let cameraAngleTitle = "New Camera Angle Collection"
            static let shootDayTitle = "New Shoot Day Collection"
            static let keywordTitle = "New Keyword Collection"
            static let videoRoleTitle = "New Video Role"
            static let audioRoleTitle = "New Audio Role"

            static let cameraAnglePrompt = "Cam A"
            static let shootDayPrompt = "Day 01"
            static let keywordPrompt = "B-Roll"
            static let rolePrompt = "Role name"

            static let cameraAngleHelp =
                "Matches clips whose Inspector ▸ Info ▸ Camera Angle equals this value."
            static let shootDayHelp =
                "Matches the keyword FCP creates when a day’s folder is imported with “Keywords: from folders”."
            static let keywordHelp = "Matches clips tagged with this keyword."
            static let roleHelp =
                "Creates the role and a Smart Collection that gathers every clip assigned to it."
        }
    }

    enum Inspector {
        static let viewPicker = "View"
        static let archives = "Recent Projects"
        static let preview = "Folder Preview"
        static let clearHistory = "Clear Recent Projects"
        static func clearConfirmTitle(count: Int) -> String {
            "Clear all \(count) recent project\(count == 1 ? "" : "s")?"
        }
        static let clearConfirmAction = "Clear All"
        static let clearConfirmMessage = "This can't be undone. The projects on disk aren't affected - only this list."
        static let backupMenu = "Backup"
        static let exportBackup = "Export Backup…"
        static let importBackup = "Import Backup…"
        static let backupErrorTitle = "Backup failed"
    }

    enum History {
        static let emptyTitle = "No Projects Yet"
        static let emptyMessage =
            "Configure the options on the left, then create a project. "
            + "Each project you create is listed here with its settings."
        static let orientation = "Orientation"
        static let size = "Size"
        static let roles = "Roles"
        static let collections = "Collections"
        static let footageSources = "Cameras"
        static let leaveFilesInPlace = "Leave files in place"
        static let copyIntoLibrary = "Copy into library"
        static let reuse = "Use These Settings"
        static let reuseHelp =
            "Restores resolution, aspect, frame rate, and leave-in-place from this project. "
            + "Roles, Smart Collections, and cameras aren't restored - only their counts were saved."
        static let delete = "Delete"
        static let storageNote = "Saved locally in Application Support. Never leaves this Mac."
    }

    enum Settings {
        static let tabs = "Settings section"
        static let autosave = "Changes are saved automatically."
    }

    nonisolated enum Customize {  // read by CustomizeTip, which TipKit requires to be nonisolated
        static let title = "Folders and Smart Collections"
        static func summary(folders: Int, collections: Int) -> String {
            "\(folders) folder\(folders == 1 ? "" : "s") · \(collections) collection\(collections == 1 ? "" : "s")"
        }
        static let button = "Customize…"
        static let tipTitle = "Make projects your own"
        static let tipMessage = "Change the folders and Smart Collections every new project gets."
    }

    enum Preview {
        static let footer = "Created inside the folder you choose when you create the project."
        static let editFolders = "Edit Folders…"
        static let editCollections = "Edit Smart Collections…"
        static func note(_ text: String) -> String { "· \(text)" }
    }

    enum Help {
        static let guide = "Slateflow Help"
        static let troubleshooting = "Troubleshooting"
        static let releaseNotes = "Release Notes"
        static let privacy = "Privacy"
        static let reportIssue = "Report an Issue…"
    }

    enum About {
        static let menuItem = "About Slateflow"
        static let openLog = "Open Log File"
        static let checkForUpdates = "Check for Updates…"
        static let privacy =
            "100% local. Slateflow runs entirely on your Mac - no telemetry, no cloud, "
            + "no tracking. Your files and configurations never leave this machine. "
            + "The only network request is the update check."
        static let github = "View on GitHub"
        static let license = "Released under the MIT License."
        static let viewLicense = "View License"
        static let licenseTitle = "MIT License"
        static let done = "Done"

        static let mitLicense = """
        MIT License

        Copyright (c) 2026 Sk Ashifali Shaikh

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        """
    }

    enum Build {
        static let menuItem = "Create Project…"
        static let button = "Choose Folder & Create Project…"
        static let buildHere = "Create Project"
        /// Leads the bottom bar's sentence; the destination folder's name follows it.
        static func creates(_ rootFolder: String) -> String { "Creates “\(rootFolder)” in" }
        static let separator = "·"
        static let change = "Change…"
        static let changeHelp = "Choose another folder for new projects"
        static let panelPrompt = "Create Here"
        static func panelMessage(rootFolder: String) -> String {
            "Choose where to create “\(rootFolder)”."
        }
        static let errorTitle = "Couldn’t create the project"
        static let ok = "OK"
        static let chooseAnother = "Choose Another Folder…"
        static let successTitle = "Project created"
        static let openInFCP = "Open in Final Cut Pro"
        static let creatingLibrary = "Creating library…"
        static let libraryNote = "Final Cut creates the project's library in its FCP folder."
        static let libraryFailed = "Final Cut didn't create the library. Check that Final Cut Pro is installed, then click Open in Final Cut Pro again."
        static let reveal = "Reveal in Finder"
        static let done = "Done"
    }
}
