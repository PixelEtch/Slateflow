//
//  ProjectNaming.swift
//  Slateflow
//
//  Root project folder naming: the "NNN - Name" sequence prefix.
//

import Foundation

enum ProjectNaming {
    static let defaultTemplateName = "SlateTemplate"

    /// Root project folder name, e.g. `001 - SlateTemplate`.
    static func folderName(sequence: Int, templateName: String) -> String {
        String(format: "%03d - %@", sequence, templateName)
    }

    /// Next free `NNN` given existing `NNN - ...` folders in `directory`. Starts at 1.
    static func nextSequence(in directory: URL) -> Int {
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let used = entries.compactMap { name -> Int? in
            let prefix = name.prefix(3)
            guard prefix.count == 3, let n = Int(prefix),
                  name.dropFirst(3).hasPrefix(" - ") else { return nil }
            return n
        }
        return (used.max() ?? 0) + 1
    }
}
