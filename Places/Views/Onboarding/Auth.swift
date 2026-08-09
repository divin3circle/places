//
//  Auth.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

// Scoped import: RiveRuntime also vends a `Color` type, which would make bare
// `Color` ambiguous against SwiftUI's.
import class RiveRuntime.RiveViewModel
import AuthenticationServices
import SwiftUI
import SwiftfulRouting

struct Auth: View {
    @Environment(\.router) var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SessionStore.self) private var session: SessionStore?

    @State private var showPanel = false
    @State private var showButton = false
    @State private var isGlowing = false
    @State private var isSigningIn = false
    @State private var currentNonce: String?
    @State private var toast: ToastData?
    // Created once — never re-instantiate the Rive runtime on body re-renders.
    @State private var riveVM = RiveViewModel(fileName: "shapes")

    var body: some View {
        VStack {
            LottieAnimationLoader(fileName: "onboarding-animation", contentMode: .center, loop: true, loopCount: 3, autoPlay: true)
            Spacer()
            authPanel
                .offset(y: showPanel ? 0 : 500)
                .opacity(showPanel ? 1 : 0)
                .padding(.horizontal)
        }
        .background(background)
        .toast($toast)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showPanel = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showButton = true
                }
            }
        }
    }

    private var background: some View {
        riveVM.view()
            .ignoresSafeArea()
            .blur(radius: 30)
            .background(
                Image("Spline")
                    .blur(radius: 20)
                    .offset(x: 200, y: 100)
            )
    }

    private var authPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Places")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .fontWidth(.expanded)
                Text("An AI supercharged travel companion for planning and exploring the unforgettable Savanna.")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            appleButton
                .scaleEffect(showButton ? 1 : 0.85)
                .opacity(showButton ? 1 : 0)

            Text("By continuing, you agree to the Terms and Privacy Policy.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            let nonce = AppleSignIn.randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = AppleSignIn.sha256(nonce)   // hashed → Apple
        } onCompletion: { result in
            handleAppleResult(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 54)
        .clipShape(Capsule())
        .overlay { glowBorder }
        .overlay {
            if isSigningIn {
                Capsule().fill(.black.opacity(0.35))
                ProgressView().tint(.white)
            }
        }
        .allowsHitTesting(!isSigningIn)
        .accessibilityLabel("Continue with Apple")
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let rawNonce = currentNonce
            else {
                toast = ToastData(message: "Couldn't read Apple credentials.", isError: true)
                return
            }
            isSigningIn = true
            Task {
                defer { isSigningIn = false }
                do {
                    // On success, the phase changes and ContentView swaps to onboarding/app.
                    try await session?.signIn(idToken: idToken, rawNonce: rawNonce, appleFullName: credential.fullName)
                } catch {
                    toast = ToastData(message: "Sign in failed. Please try again.", isError: true)
                }
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                toast = ToastData(message: "Sign in failed. Please try again.", isError: true)
            }
        }
    }

    private var glowBorder: some View {
        let stroke = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)

        return Capsule()
            .stroke(Color.accent.gradient, style: stroke)
            .mask {
                let clearColors: [Color] = Array(repeating: .clear, count: 3)

                Capsule()
                    .fill(AngularGradient(
                        colors: clearColors + [Color.white] + clearColors,
                        center: .center,
                        angle: .degrees(isGlowing ? 360 : 0)
                    ))
            }
            .padding(-1)
            .blur(radius: 2)
            .allowsHitTesting(false)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    isGlowing = true
                }
            }
            .onDisappear { isGlowing = false }
    }
}

#Preview {
    RouterView { _ in
        Auth()
    }
}
