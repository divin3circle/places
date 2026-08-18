//
//  NotifiationsOnboarding.swift
//  Places
//
//  Created by Sylus Abel on 29/07/2026.
//

import SwiftUI
import UserNotifications

struct NotificationOnboardingConfig {
    var title: String
    var content: String
    var notificationTitle: String
    var notificationContent: String
    var primaryButtonTitle: String
    var secondaryButtonTitle: String
}

struct NotifiationsOnboarding<NotificationLogo: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var animateNotification: Bool = false
    @State private var loopContinues: Bool = true
    @State private var askPermission: Bool = false
    @State private var showArrow: Bool = false
    @State private var authorization: UNAuthorizationStatus = .notDetermined
    @State private var currentStep: Int = 2
    
    var config: NotificationOnboardingConfig
    @ViewBuilder var notificationLogo: NotificationLogo
    var onPersmissionChange: (_ isApproved: Bool) -> ()
    var onPrimaryButtonTap: () -> ()
    var onSecondaryButtonTap: () -> ()
    var onFinish: () -> ()
    
    var body: some View {
        ZStack{
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .ignoresSafeArea()
                    .blurOpacity(askPermission)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(foregroundColor)
                    .offset(x: iOS26 ? 75 : 70, y: 150)
                    .blurOpacity(showArrow)
            }
            .allowsHitTesting(false)
            VStack(spacing: 0) {
                ProgressViewer(steps: 4, currentStep: $currentStep)
                    .padding(.horizontal)
                iPhonePreview()
                    .padding(.top, 15)
                    .blurOpacity(!askPermission)
                
                VStack(spacing: 20) {
                    Text(config.title)
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(config.content)
                        .font(.callout)
                        .fontDesign(.rounded)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        if authorization == .authorized {
                            onPrimaryButtonTap()
                        } else if authorization == .denied {
                            if let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(settingsURL)
                            }
                        } else {
                            askNotificationPermission()
                        }
                    } label: {
                        Text(
                            authorization == .authorized ? "Finish Onboarding" :
                                authorization == .denied ? "Go to Settings" :
                                config.primaryButtonTitle
                        )
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.primary, in: .capsule)
                    }
                    
                    // Notifications are always optional — the user must be able to
                    // continue without granting them (App Review 4.5.4). Keep a skip
                    // path in every non-authorized state, including `.denied`, so the
                    // "Go to Settings" button is never the only way forward.
                    if authorization != .authorized {
                        Button {
                            onSecondaryButtonTap()
                        } label: {
                            Text(authorization == .denied ? "Maybe later" : config.secondaryButtonTitle)
                                .fontWeight(.medium)
                                .fontDesign(.rounded)
                                .foregroundStyle(backgroundColor.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .blurOpacity(!askPermission)
            }
        }
        .onDisappear {
            loopContinues = false
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let authorization = settings.authorizationStatus
            self.authorization = authorization
            
            if authorization == .authorized {
                onPersmissionChange(true)
            }
            
            if authorization == .denied {
                onPersmissionChange(false)
            }
        }
    }
    
    @ViewBuilder
    private func iPhonePreview() -> some View {
        GeometryReader {
            let size = $0.size
            let scale = min(size.height/340, 1)
            let width: CGFloat = 320
            let cornerRadius: CGFloat = 30
            
            ZStack(alignment: .top){
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(0.06))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.5)
                
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        RoundedRectangle(cornerRadius: 20)
                        RoundedRectangle(cornerRadius: 20)
                    }
                    .frame(height: 120)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 15), count: 4),spacing: 15) {
                        ForEach(1...12, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 55)
                        }
                    }
                }
                .padding(20)
                .padding(.top, 20)
                .foregroundStyle(backgroundColor.opacity(0.1))
                
                HStack(spacing: 4) {
                    Text("9:41")
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.50percent")
                }
                .font(.caption2)
                .fontDesign(.rounded)
                .padding(.horizontal, 20)
                .padding(.top, 15)
                
                NotificationView()
            }
            .frame(width: width)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .mask {
                LinearGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .clear, location: 0.9)
                ], startPoint: .top, endPoint: .bottom)
                .padding(-1)
            }
            .scaleEffect(scale, anchor: .top)
        }
    }
    
    @ViewBuilder
    private func NotificationView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            notificationLogo
            
            VStack(alignment: .leading,spacing: 4) {
                HStack {
                    Text(config.notificationTitle)
                        .font(.callout)
                        .fontDesign(.rounded)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    Text("Now")
                        .font(.caption2)
                        .fontDesign(.rounded)
                        .foregroundStyle(.gray)
                }
                Text(config.notificationContent)
                    .font(.caption2)
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .gray.opacity(0.5), radius: 1.5)
        .padding(.horizontal, 12)
        .padding(.top, 40)
        .offset(y: animateNotification ? 0 : -200)
        .clipped()
        .task {
            await loopAnimation()
        }
    }
    
    private func loopAnimation() async {
        try? await Task.sleep(for: .seconds(0.5))
        
        withAnimation(.smooth(duration: 1)) {
            animateNotification = true
        }
        
        try? await Task.sleep(for: .seconds(4))
        
        withAnimation(.smooth(duration: 1)) {
            animateNotification = false
        }
        
        guard loopContinues else { return }
        try? await Task.sleep(for: .seconds(1.3))
        await loopAnimation()
    }
    
    private func askNotificationPermission() {
        Task { @MainActor in
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                askPermission = true
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                showArrow  = true
            }
            
            let status = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            let authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            onPersmissionChange(status)
            
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                askPermission = false
                showArrow  = false
                self.authorization = authorization
            }
            
            
            
        }
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var foregroundColor: Color {
        colorScheme != .dark ? .white : .black
    }
}

#Preview {
    NotifiationsOnboarding(
        config: NotificationOnboardingConfig(
            title: "Stay Connected with\nPush Notifications",
            content: "More samples allowed",
            notificationTitle: "Sample1",
            notificationContent: "More samples1 allowed",
            primaryButtonTitle: "Continue",
            secondaryButtonTitle: "Ask Later"
        )
    ) {
            Text("Logo")
        } onPersmissionChange: { isApproved in
            print("changed")
        } onPrimaryButtonTap: {
            print("prinmary button")
        } onSecondaryButtonTap: {
            print("secondary button")
        } onFinish: {
            print("finished")
        }
}

fileprivate extension View {
    @ViewBuilder
    func blurOpacity(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .opacity(status ? 1 : 0)
            .blur(radius: status ? 0 : 10)
    }
    
    var iOS26: Bool {
        if #available(iOS 26, *){
            return true
        }
        
        return false
    }
}
