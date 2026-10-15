//
//  AboutView.swift
//  Slateflow
//
//  "About Slateflow" window - version, privacy stance, MIT license, repo link, credit.
//

import SwiftUI

enum AppInfo {
    static let name = "Slateflow"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    static var versionLine: String { "Version \(version) (Build \(build))" }

    /// Single source: the Info.plist copyright Finder's Get Info also shows.
    static var copyright: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© 2026 Sk Ashifali Shaikh"
    }

    static let repositoryURL = URL(string: "https://github.com/PixelEtch/Slateflow")!
}

struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(Strings.About.menuItem) { openWindow(id: "about") }
    }
}

struct AboutView: View {
    @State private var showingLicense = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)

            VStack(spacing: Spacing.xxs) {
                Text(AppInfo.name).font(.title2.weight(.semibold))
                Text(AppInfo.versionLine).font(.callout).foregroundStyle(.secondary)
            }

            Divider()

            Label {
                Text(Strings.About.privacy)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: SFSymbol.privacy).foregroundStyle(Palette.secure)
            }
            .font(.callout)
            .frame(maxWidth: 340, alignment: .leading)

            Divider()

            VStack(spacing: Spacing.xs) {
                Link(Strings.About.github, destination: AppInfo.repositoryURL)

                HStack(spacing: Spacing.xxs) {
                    Text(Strings.About.license).foregroundStyle(.secondary)
                    Button(Strings.About.viewLicense) { showingLicense = true }
                        .buttonStyle(.link)
                }
                .font(.caption)

                Text(AppInfo.copyright).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg + Spacing.xs)
        .frame(width: 420)
        .sheet(isPresented: $showingLicense) { MITLicenseSheet() }
    }
}

struct MITLicenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.About.licenseTitle).font(.headline)
            ScrollView {
                Text(Strings.About.mitLicense)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Spacer()
                Button(Strings.About.done) { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Spacing.lg)
        .frame(minWidth: 420, idealWidth: 480, minHeight: 260, idealHeight: 340)
    }
}

#Preview { AboutView() }
