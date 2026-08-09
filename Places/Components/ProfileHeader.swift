//
//  ProfileHeader.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftfulRouting

struct ProfileHeader: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.router) private var router
    @Binding var isLargerHeader: Bool
    @Binding var topInset: CGFloat

    @Environment(SessionStore.self) private var session: SessionStore?

    private var displayName: String { session?.currentProfile?.name ?? "Traveler" }
    private var displayEmail: String { session?.currentProfile?.email ?? "" }

    var body: some View {
        VStack(spacing: 12) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 100, height: isLargerHeader ? 300 : 100)
                .clipShape(.circle)
            
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
    }
    
    @ViewBuilder
    private func LogoView() -> some View {
        ZStack {
            Rectangle()
                .fill(.black)
            
            Image("profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: isLargerHeader ? 200 : 55)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .offset(y: isLargerHeader ? -topInset : 0)
        }
    }
    
    @ViewBuilder
    private func CustomNavigationBar() -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(displayName)
                .fontDesign(.rounded)
                .font(.title)
                .fontWeight(.semibold)

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
