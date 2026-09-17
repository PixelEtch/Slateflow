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
        Section(Strings.FCP.section) {
            Toggle(Strings.FCP.leaveFilesInPlace, isOn: $store.fcp.keepMediaInPlace)
                .help(Strings.FCP.leaveFilesInPlaceHelp)
        }
    }
}
