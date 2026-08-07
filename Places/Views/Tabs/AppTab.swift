//
//  AppTab.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

struct AppTab: View {
    @State private var activeTab: AppTabs = .home
    @State private var progress: CGFloat = 0
    @State private var showCreate: Bool = false
    @StateObject private var sponsoredViewModel = SponsoredViewModel()
    @Namespace private var sponsoredAnimation

    var body: some View {
        TabView(selection: $activeTab) {
            Tab.init(value: .home) {
                ScrollView(.vertical) {
                   HomeTab(sponsoredAnimation: sponsoredAnimation)
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
            Tab.init(value: .lounges) {
                ScrollView(.vertical) {
                    ChatsTab()
                }
                .scrollableHeader(dismissDistance: 60, header: {
                    ChatsHeader()
                })
                .hideNativeTabBar()
                .adoptForCustomTabBar($progress)
                .scrollIndicators(.hidden)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaPadding([.horizontal, .bottom], 15)
            }
            Tab.init(value: .profile) {
                ProfileTab()
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
            .glassEffect(.regular, in: .capsule)
            .scaleEffect(1 - (progress * 0.15), anchor: .bottom)
            .padding(.horizontal, 20)
        }
        .overlay {
            if sponsoredViewModel.showCard {
                SponsoredDetails(animation: sponsoredAnimation)
                    .transition(.opacity)
            }
        }
        .environmentObject(sponsoredViewModel)
        .sheet(isPresented: $showCreate) {
            CreateTripSheet()
        }
    }
}

#Preview {
    NavigationStack {
        AppTab()
    }
}
