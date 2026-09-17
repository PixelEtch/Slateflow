//
//  Security.swift
//  Slateflow
//
//  Trust-boundary helpers: filename sanitisation (path-traversal defense),
//  a destination-containment check, and explicit POSIX permissions for output.
//

import Foundation

enum SlateError: LocalizedError {
    /// The computed project path resolves outside the folder the user chose.
    case destinationEscape(String)
    /// A folder with the computed name already exists at the destination.
    case destinationOccupied(String)

    var errorDescription: String? {
        switch self {
        case .destinationEscape:
            return "The project name would create files outside the folder you chose. Rename it and try again."
        case .destinationOccupied(let name):
            return "A folder named “\(name)” already exists there. Rename the template or pick another location."
        }
    }
}

/// Reduces an arbitrary user string to a single, filesystem-safe path component.
nonisolated enum SafeName {
    private static let maxLength = 200   // well under the 255-byte APFS limit

    /// No path separators, no leading dots (so `.`, `..`, dotfiles can't be produced),
    /// no control or invisible/zero-width characters (homograph / RTL-override defense).
    /// Returns `fallback` when nothing usable remains.
    static func component(_ raw: String, fallback: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop control chars and invisible / zero-width scalars (homograph, RTL-override).
        s = String(String.UnicodeScalarView(s.unicodeScalars.filter { scalar in
            scalar.value >= 0x20 && !scalar.properties.isDefaultIgnorableCodePoint
        }))

        // Neutralise every path separator (POSIX, Windows, classic Mac / APFS resource fork).
        for separator in ["/", "\\", ":"] {
            s = s.replacingOccurrences(of: separator, with: "-")
        }

        // Collapse any run of 2+ dots so "..", "..." can't survive anywhere in the name.
        s = s.replacingOccurrences(of: "\\.{2,}", with: "-", options: .regularExpression)
        // Collapse dash runs left by the substitutions above.
        s = s.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
        // Strip leading dots (dotfile prevention) and trim junk from the ends.
        while s.hasPrefix(".") { s.removeFirst() }
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "-. "))

        if s.count > maxLength {
            s = String(s.prefix(maxLength)).trimmingCharacters(in: CharacterSet(charactersIn: "-. "))
        }

        return s.isEmpty ? fallback : s
    }
}

extension URL {
    /// True when `self` is `parent` or resolves to somewhere inside it
    /// (after resolving `.`, `..`, and symlinks on both sides).
    func isContained(in parent: URL) -> Bool {
        let child = resolvingSymlinksInPath().standardizedFileURL.path
        let root = parent.resolvingSymlinksInPath().standardizedFileURL.path
        return child == root || child.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }
}

nonisolated enum FilePermissions {
    static let directory: Int = 0o755   // owner rwx, group/other r-x
    static let file: Int = 0o644        // owner rw-, group/other r--

    /// Best-effort chmod; a failure here never blocks a build.
    static func harden(file url: URL) {
        try? FileManager.default.setAttributes(
            [.posixPermissions: file], ofItemAtPath: url.path)
    }
}
