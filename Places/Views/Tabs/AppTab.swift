//
//  AppTab.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

struct AppTab: View {
    @Environment(Connectivity.self) private var connectivity: Connectivity?
    @Environment(SessionStore.self) private var session: SessionStore?
    @State private var activeTab: AppTabs = .home
    @State private var progress: CGFloat = 0
    @State private var showCreate: Bool = false

    @State private var pendingConfig: TripConfig?
    @State private var itineraryConfig: TripConfig?
    @State private var sponsoredViewModel = SponsoredViewModel()
    @Namespace private var sponsoredAnimation

    var body: some View {
        TabView(selection: $activeTab) {
            Tab.init(value: .home) {
                ScrollView(.vertical) {
                   HomeTab(sponsoredAnimation: sponsoredAnimation,
                           onSwitchTab: { activeTab = $0 })
                }
                .scrollableHeader(dismissDistance: 60, header: {
                    HomeHeader(onProfileTap: { activeTab = .profile })
                })
                .adoptForCustomTabBar($progress)
                .hideNativeTabBar()
                .scrollIndicators(.hidden)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaPadding([.horizontal, .bottom], 15)
                
            }
            Tab.init(value: .explore) {
                ExploreTab()
                    .adoptForCustomTabBar($progress)
                    .hideNativeTabBar()
                    .scrollIndicators(.hidden)
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaPadding([.bottom], 15)
            }
            Tab.init(value: .trips) {
                MyTrips()
                    .adoptForCustomTabBar($progress)
                    .hideNativeTabBar()
                    .scrollIndicators(.hidden)
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaPadding([.bottom], 15)
            }
            // Lounges (Chats) is hidden for v1 — no messaging backend yet. Restore
            // this Tab + the .lounges entry in CustomTabBar when Chats is built.
            Tab.init(value: .profile) {
                ProfileTab(onSwitchTab: { activeTab = $0 })
                    .adoptForCustomTabBar($progress)
                    .hideNativeTabBar()
                    .scrollIndicators(.hidden)
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaPadding([.bottom], 15)
            }
        }
        .overlay(alignment: .bottom) {
            CustomTabBar(
                selection: $activeTab,
                onCreate: { showCreate = true },
                onInteraction: {
                    if progress != 0 {
                        withAnimation(.interpolatingSpring(duration: 0.25, bounce: 0, initialVelocity: 0)) {
                            progress = 0
                        }
                    }
                }
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            // Solid, theme-adaptive bar: white in light mode, near-black in dark.
            // A hairline border + soft shadow keep it reading as a floating bar
            // (a plain black capsule over dark content would otherwise disappear).
            .background(Color(.systemBackground), in: .capsule)
            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .scaleEffect(1 - (progress * 0.15), anchor: .bottom)
            .padding(.horizontal, 20)
        }
        .overlay {
            if sponsoredViewModel.showCard {
                SponsoredDetails(animation: sponsoredAnimation)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if connectivity?.isOnline == false {
                OfflineBanner()
            }
        }
        .animation(.snappy, value: connectivity?.isOnline)
        // Self-heal a stale/synthesized profile (e.g. default avatar) whenever the
        // app surfaces or connectivity returns — no logout/login needed.
        .task(id: connectivity?.isOnline) {
            if connectivity?.isOnline != false { await session?.refreshProfile() }
        }
        .environment(sponsoredViewModel)
        .sheet(isPresented: $showCreate, onDismiss: {
            if let pendingConfig {
                itineraryConfig = pendingConfig
                self.pendingConfig = nil
            }
        }) {
            CreateTripSheet(onGenerate: { config in
                pendingConfig = config
                showCreate = false
            })
        }
        .fullScreenCover(item: $itineraryConfig) { config in
            GenerateItineraryView(config: config)
        }
    }
}

#Preview {
    NavigationStack {
        AppTab()
    }
}
