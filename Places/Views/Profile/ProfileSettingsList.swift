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
    @AppStorage(AIPreferenceKey.model) private var aiModelRaw = ""
    @State private var showModelPicker = false

    @Environment(SessionStore.self) private var session: SessionStore?
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @State private var showPaywall = false

    private let termsURL = URL(string: "https://places-web.vercel.app/terms")!
    private let privacyURL = URL(string: "https://places-web.vercel.app/privacy")!
    private let faqURL = URL(string: "https://places-web.vercel.app/support")!
    private let feedbackURL = URL(string: "mailto:sylusabel1@gmail.com?subject=Places%20Feedback")!

    private var appearance: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            accountSection
            proSection
            preferencesSection
            tripsSection
            supportSection
            accountActionsSection

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
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var proSection: some View {
        SettingsSection {
            SettingsRow(
                icon: "crown.fill",
                iconColor: .accent,
                title: (purchases?.isPro == true) ? "Places Pro" : "Upgrade to Pro",
                accessory: (purchases?.isPro == true) ? .badge(text: "Active", tint: .accent) : .chevron,
                onTap: { showPaywall = true }
            )
            SettingsRow(
                icon: "arrow.clockwise",
                title: "Restore purchases",
                accessory: .chevron,
                onTap: { Task { await purchases?.restore() } }
            )
        }
    }

    private var aiModelLabel: String {
        AIModelKind(rawValue: aiModelRaw)?.title ?? "Not set"
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var accountActionsSection: some View {
        SettingsSection {
            #if DEBUG
            // Debug-only: never ship the onboarding reset to real users.
            SettingsRow(
                icon: "arrow.counterclockwise",
                title: "Reset onboarding (debug)",
                accessory: .chevron,
                onTap: resetOnboarding
            )
            #endif
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.forward",
                title: "Log out",
                accessory: .chevron,
                onTap: logout
            )
        }
        .padding(.top, 25)
    }

    private func logout() {
        router.dismissAllScreens()
        Task { await session?.signOut() }
    }

    private func resetOnboarding() {
        router.dismissAllScreens()
        Task { await session?.resetOnboarding() }
    }

    private var preferencesSection: some View {
        SettingsSection {
            AppearancePickerRow(selection: appearance)
            SettingsRow(
                icon: "sparkles",
                title: "AI model",
                accessory: .value(aiModelLabel),
                onTap: { showModelPicker = true }
            )
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
