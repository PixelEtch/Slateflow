//
//  ConfigurationForm.swift
//  Slateflow
//
//  The sidebar form: what changes per project. Set-once options live in Settings.
//  Each Section is its own component; the grouped Form owns section spacing, so
//  no manual padding here.
//

import SwiftUI

struct ConfigurationForm: View {
    @Bindable var store: SlateStore

    var body: some View {
        Form {
            ProjectFolderSection(store: store)
            FormatSection(store: store)
            FootageSourcesSection(store: store)
            CustomizeSection(store: store)
        }
        .formStyle(.grouped)
    }
}
