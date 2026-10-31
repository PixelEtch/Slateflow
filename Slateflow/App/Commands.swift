//
//  Commands.swift
//  Slateflow
//
//  App-wide behaviour: the Create Project menu command, and ending text editing on a
//  click outside a field.
//

import SwiftUI
import AppKit

// MARK: - Click outside to end editing

/// Clicking anywhere that isn't a text field ends text editing, as in System Settings.
/// AppKit keeps the cursor in a field until another control takes focus.
enum EndEditingOnOutsideClick {
    private static var monitor: Any?

    static func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let window = event.window,
                  window.firstResponder is NSText,          // a field is being edited
                  !isText(window.contentView?.hitTest(event.locationInWindow))
            else { return event }
            // After the click is handled, so a button or switch still gets it.
            DispatchQueue.main.async {
                if window.firstResponder is NSText { window.makeFirstResponder(nil) }
            }
            return event
        }
    }

    /// True for a text field or its field editor, or anything inside one.
    private static func isText(_ view: NSView?) -> Bool {
        var view = view
        while let v = view {
            if v is NSText || v is NSTextField { return true }
            view = v.superview
        }
        return false
    }
}

// MARK: - Menu-bar wiring

/// Lets the `Create Project…` menu command trigger the same flow as the bottom bar.
// A FocusedValueKey, not `@Entry`: `@Entry` warns that a stored closure can't be
// compared, so every update would invalidate the menu command.
struct BuildActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var buildAction: (() -> Void)? {
        get { self[BuildActionKey.self] }
        set { self[BuildActionKey.self] = newValue }
    }
}

struct BuildCommand: View {
    @FocusedValue(\.buildAction) private var buildAction

    var body: some View {
        Button(Strings.Build.menuItem) { buildAction?() }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(buildAction == nil)
    }
}
