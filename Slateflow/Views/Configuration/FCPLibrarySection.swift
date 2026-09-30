//
//  FCPLibrarySection.swift
//  Slateflow
//
//  The "leave files in place" toggle.
//

import SwiftUI

struct FCPLibrarySection: View {
    @Bindable var store: SlateStore

    var body: some View {
        Section {
            Toggle(Strings.FCP.leaveFilesInPlace, isOn: $store.fcp.keepMediaInPlace)
        } header: {
            Text(Strings.FCP.section)
        } footer: {
            Text(Strings.FCP.leaveFilesInPlaceHelp)
        }
    }
}
