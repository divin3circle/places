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
    @Binding var isLargerHeader: Bool
    @Binding var topInset: CGFloat

    @Environment(SessionStore.self) private var session: SessionStore?
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?

    @State private var pickedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var toast: ToastData?

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
                        // Lifetime members get an animated gold avatar frame.
                        if isLifetime {
                            LifetimeFrameView(size: isLargerHeader ? 300 : 132)
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
            HStack(spacing: 8) {
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
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "wallet.bifold.fill", title: "Wallet", onTap: {
                router.showScreen(.push) { _ in Wallets() }
            })
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "rectangle.portrait.and.arrow.forward", title: "Logout", onTap: {
                router.dismissAllScreens()
                Task { await session?.signOut() }
            })
            CustomActionButton(isLargerHeader: isLargerHeader, icon: "ellipsis", title: "More", onTap: {})
        }
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
