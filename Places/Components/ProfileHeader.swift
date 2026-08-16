//
//  ProfileHeader.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftfulRouting
import PhotosUI

struct ProfileHeader: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.router) private var router
    @Environment(\.openURL) private var openURL
    @Binding var isLargerHeader: Bool
    @Binding var topInset: CGFloat
    /// Switches the root tab (used by the "Saved" action → Trips tab).
    var onSwitchTab: (AppTabs) -> Void = { _ in }

    @Environment(SessionStore.self) private var session: SessionStore?
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?

    // Stub links until the marketing site's pages are live (see task: site update).
    private let supportURL = URL(string: "https://places-web.vercel.app/support")!
    private let contactURL = URL(string: "mailto:sylusabel1@gmail.com")!
    private let privacyURL = URL(string: "https://places-web.vercel.app/privacy")!
    private let termsURL = URL(string: "https://places-web.vercel.app/terms")!

    @State private var pickedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var toast: ToastData?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    private var displayName: String { session?.currentProfile?.name ?? "Traveler" }
    private var displayEmail: String { session?.currentProfile?.email ?? "" }
    private var isPro: Bool { purchases?.isPro ?? false }
    private var isLifetime: Bool { session?.currentProfile?.planProduct == "piea_pro_lifetime" }

    var body: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 100, height: isLargerHeader ? 300 : 100)
                    .clipShape(.circle)
                    .overlay {
                        if isLifetime {
                            LifetimeFrameView(size: isLargerHeader ? 370 : 162)
                                .allowsHitTesting(false)
                                .padding(.bottom, isLargerHeader ?105 : 12)
                        }
                    }
                    .overlay {
                        if isUploading {
                            ZStack {
                                Circle().fill(.black.opacity(0.35))
                                ProgressView().tint(.white)
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(Color.accentColor))
                            .offset(x: -6, y: -6)
                            .opacity(isLargerHeader ? 0 : 1)   // badge in the collapsed avatar
                    }
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .disabled(isUploading)

            VStack(spacing: 20) {
                CustomNavigationBar()
                    .foregroundStyle(isLargerHeader ? .white : .primary)
                
                HeaderActions()
                    .foregroundStyle(isLargerHeader ? .white : .primary)
                    .geometryGroup()
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
        .background(alignment: .top) {
            GeometryReader {
                let size = $0.size
                let minY = $0.frame(in: .global).minY
                let topOffset = isLargerHeader ? minY : 0
                
                LogoView()
                    .frame(
                        width: size.width,
                        height: size.height + topOffset
                    )
                    .clipShape(.rect(cornerRadius: isLargerHeader ? 0 : 50))
                    .offset(y: -topOffset)
            }
            .frame(
                width: isLargerHeader ? nil : 100,
                height: isLargerHeader ? nil : 100
            )
        }
        .padding(.top, 15)
        .toast($toast)
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { Task { await performDelete() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, saved trips, and token balance. If you have an active subscription, deleting your account won't cancel it — manage it in Settings → Subscriptions. This can't be undone.")
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                isUploading = true
                defer { isUploading = false; pickedItem = nil }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let jpeg = AvatarImage.jpegData(from: image) else {
                        toast = ToastData(message: "Couldn't read that photo.", isError: true)
                        return
                    }
                    try await session?.updateAvatar(jpegData: jpeg)
                } catch {
                    toast = ToastData(message: "Couldn't update photo. Please try again.", isError: true)
                }
            }
        }
    }

    @ViewBuilder
    private func LogoView() -> some View {
        let side: CGFloat = isLargerHeader ? 200 : 55
        ZStack {
            Rectangle()
                .fill(.black)

            Group {
                if let url = session?.currentProfile?.avatarURL, !url.isEmpty {
                    RemoteImage(url, width: side, height: side)
                        .frame(width: side, height: side)
                        .clipShape(Circle())
                } else {
                    Image("profile")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: side)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            .offset(y: isLargerHeader ? -topInset : 0)
        }
    }
    
    @ViewBuilder
    private func CustomNavigationBar() -> some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 2) {
                Text(displayName)
                    .fontDesign(.rounded)
                    .font(.title)
                    .fontWeight(.semibold)
                if isPro { ProBadgeView(size: 26) }
            }

            Text(displayEmail)
                .foregroundStyle(.gray.opacity(0.9))
                .font(.system(size: 16))
                .fontDesign(.rounded)
        }
        .frame(maxWidth: .infinity, alignment: isLargerHeader ? .leading : .center)
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let progress = max(min(minY / 50, 1), 0)
            
            return content
                .scaleEffect(0.7 + (0.3 * progress))
                .offset(y: minY < 0 ? -minY : 0)
        
        }
        .background(NavigationBarBakground())
        .zIndex(1)
    }
    
    @ViewBuilder
    func NavigationBarBakground() -> some View {
        GeometryReader {
            let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
            let opacity: CGFloat = 1.0 - max(min(minY / 50, 1), 0)
            let tint: Color = colorScheme == .dark ? Color.black : Color.white
            
            ZStack {
                
                if #available(iOS 26, *) {
                    Rectangle()
                        .fill(.clear)
                        .glassEffect(.clear.tint(tint.opacity(0.8)), in: .rect)
                        .mask {
                            LinearGradient(colors: [
                                .black,
                                .black,
                                .black,
                                .black.opacity(0.9),
                                .black.opacity(0.4),
                                .clear
                            ], startPoint: .top, endPoint: .bottom)
                        }
                } else {
                    Rectangle()
                        .fill(tint)
                        .mask {
                            LinearGradient(colors: [
                                .black,
                                .black,
                                .black,
                                .black.opacity(0.9),
                                .black.opacity(0.4),
                                .clear
                            ], startPoint: .top, endPoint: .bottom)
                        }
                }
            }
            .padding(-20)
            .padding(.top, -topInset)
            .offset(y: -minY)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func HeaderActions() -> some View {
        HStack(spacing: 6) {
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "airplane.up.right.app.fill", title: "Trips", onTap: {
                router.showScreen(.push) { _ in MyTripsView() }
            })
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "bookmark.fill", title: "Saved", onTap: {
                onSwitchTab(.trips)
            })
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "rectangle.portrait.and.arrow.forward", title: "Logout", onTap: {
                router.dismissAllScreens()
                Task { await session?.signOut() }
            })
            Menu {
                Button { openURL(supportURL) } label: { Label("Report an issue", systemImage: "exclamationmark.bubble") }
                Button { openURL(contactURL) } label: { Label("Contact developer", systemImage: "envelope") }
                Button { openURL(privacyURL) } label: { Label("Privacy Policy", systemImage: "hand.raised") }
                Button { openURL(termsURL) } label: { Label("Terms of Service", systemImage: "doc.text") }
                Divider()
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            } label: {
                actionButtonLabel(icon: "ellipsis", title: "More")
            }
        }
    }

    /// Permanently deletes the account, then dismisses so the root switches back
    /// to the auth screen (SessionStore moves to `.signedOut`). Keeps the user in
    /// place and surfaces a toast if the server delete fails.
    private func performDelete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await session?.deleteAccount()
            router.dismissAllScreens()
        } catch {
            toast = ToastData(message: "Couldn't delete your account. Please try again.", isError: true)
        }
    }

    /// The visual for an action tile (shared by the More menu so it matches the
    /// CustomActionButton tiles exactly).
    @ViewBuilder
    private func actionButtonLabel(icon: String, title: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.title)
                .frame(height: 30)
            Text(title)
                .font(.caption)
                .fontDesign(.rounded)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.background)
                    .opacity(isLargerHeader ? 0 : 1)
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
                    .opacity(isLargerHeader ? 0.8 : 0)
                    .environment(\.colorScheme, .dark)
            }
        }
        .contentShape(.rect)
    }
    
    struct CustomActionButton: View {
        var isLargerHeader: Bool
        var icon: String
        var title: String
        var onTap: () -> () = { }
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.title)
                        .frame(height: 30)
                    
                    Text(title)
                        .font(.caption)
                        .fontDesign(.rounded)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.background)
                            .opacity(isLargerHeader ? 0 : 1)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.ultraThinMaterial)
                            .opacity(isLargerHeader ? 0.8 : 0)
                            .environment(\.colorScheme, .dark)
                    }
                }
                .contentShape(.rect)
            }
        }
    }
}

#Preview {
    ProfileTab()
}
