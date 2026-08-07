//
//  ProfileSettingsList.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import StoreKit
import UIKit
import SwiftfulRouting

struct ProfileSettingsList: View {
    @Environment(\.router) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @AppStorage("appearanceMode") private var appearanceRaw = AppearanceMode.system.rawValue

    private let profile = UserProfile.current

    private let termsURL = URL(string: "https://places.app/terms")!
    private let privacyURL = URL(string: "https://places.app/privacy")!
    private let faqURL = URL(string: "https://places.app/faq")!
    private let feedbackURL = URL(string: "mailto:support@places.app?subject=Places%20Feedback")!

    private var appearance: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            accountSection
            preferencesSection
            tripsSection
            supportSection

            Divider()
                .padding(.top, 24)
                .padding(.bottom, 16)

            Text(versionString)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var accountSection: some View {
        SettingsSection {
            SettingsRow(icon: "envelope", title: "Email", accessory: .value(profile.email))
            SettingsRow(icon: "person", title: "Name", accessory: .value(profile.name))
            SettingsRow(
                icon: "shippingbox",
                title: "Current plan",
                accessory: .badge(text: profile.plan.rawValue, tint: profile.plan.tint)
            )
        }
    }

    private var preferencesSection: some View {
        SettingsSection {
            AppearancePickerRow(selection: appearance)
            SettingsRow(
                icon: "bell",
                title: "Notifications",
                accessory: .chevron,
                onTap: openNotificationSettings
            )
        }
        .padding(.top, 25)
    }

    private var tripsSection: some View {
        SettingsSection {
            SettingsRow(
                icon: "airplane",
                title: "My Trips",
                accessory: .chevron,
                onTap: { router.showScreen(.push) { _ in MyTripsView() } }
            )
        }
    }

    private var supportSection: some View {
        SettingsSection {
            SettingsRow(
                icon: "questionmark.circle",
                title: "Frequently asked questions",
                accessory: .externalLink,
                onTap: { openURL(faqURL) }
            )
            SettingsRow(
                icon: "star",
                title: "Rate Places on the App Store",
                accessory: .chevron,
                onTap: { requestReview() }
            )
            SettingsRow(
                icon: "bubble.left",
                title: "Give feedback",
                accessory: .externalLink,
                onTap: { openURL(feedbackURL) }
            )
            SettingsRow(
                icon: "doc.text",
                title: "Terms of Service",
                accessory: .externalLink,
                onTap: { openURL(termsURL) }
            )
            SettingsRow(
                icon: "lock",
                title: "Privacy Policy",
                accessory: .externalLink,
                onTap: { openURL(privacyURL) }
            )
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview {
    RouterView { _ in
        ScrollView {
            ProfileSettingsList()
        }
        .background(.fill.tertiary)
    }
}
