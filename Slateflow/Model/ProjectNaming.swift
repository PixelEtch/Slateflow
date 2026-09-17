//
//  ProjectNaming.swift
//  Slateflow
//
//  Root project folder naming: the "NNN - Name" sequence prefix.
//

import Foundation

/// Root project folder name, e.g. `001 - SlateTemplate`.
struct FolderName {
    var sequence: Int
    var templateName: String

    var formatted: String { String(format: "%03d - %@", sequence, templateName) }
}

enum ProjectNaming {
    static let defaultTemplateName = "SlateTemplate"

    /// Next free `NNN` given existing `NNN - ...` folders in `directory`. Starts at 1.
    static func nextSequence(in directory: URL, fileManager: FileManager = .default) -> Int {
        let entries = (try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? []
        let used = entries.compactMap { name -> Int? in
            let prefix = name.prefix(3)
            guard prefix.count == 3, let n = Int(prefix),
                  name.dropFirst(3).hasPrefix(" - ") else { return nil }
            return n
        }
        return (used.max() ?? 0) + 1
    }
}
