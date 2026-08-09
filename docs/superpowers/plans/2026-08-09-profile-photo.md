# Profile Photo Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a signed-in user set a profile photo — tap avatar → PhotosPicker → downscale → upload to the `avatars` bucket → persist `profiles.avatar_url` → show it in `ProfileHeader`.

**Architecture:** A `AvatarStoring` seam (prod wraps `client.storage.from("avatars")`) uploads the resized JPEG; `SessionStore.updateAvatar` uploads then persists via `ProfileProviding.updateAvatarURL` and updates `currentProfile.avatarURL`; `ProfileHeader` hosts the picker + badge + spinner + toast and shows `RemoteImage` (or `Image("profile")`).

**Tech Stack:** supabase-swift Storage, PhotosUI (`PhotosPicker`), UIKit (`UIGraphicsImageRenderer`), Swift Testing.

## Global Constraints
- iOS 26.5, Swift 6, `-default-isolation=MainActor`; `@Observable`; no optimistic mutation (write `avatar_url` only after a successful upload).
- Storage path `avatars/<uid-lowercased>/<uuid-lowercased>.jpg` — folder MUST be the **lowercased** auth uid to satisfy the owner-write RLS (`auth.uid()::text` is lowercase).
- Verify: `xcodebuild test -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PlacesTests`; build via `xcodebuild build …`; interactive on iPhone 17 Pro.

## File Structure
**Create:** `Places/Utilities/AvatarImage.swift`, `Places/Services/AvatarStore.swift`; tests `PlacesTests/AvatarImageTests.swift`, `PlacesTests/AvatarUpdateTests.swift`.
**Modify:** `Places/Services/ProfileRepository.swift` (`updateAvatarURL`), `PlacesTests/Fakes/Fakes.swift` (`updateAvatarURL` + `FakeAvatarStoring`), `Places/View Models/SessionStore.swift` (dep + `updateAvatar`), `PlacesTests/SessionStoreTests.swift` (makeStore ctor), `Places/App/PlacesApp.swift` (inject), `Places/Components/ProfileHeader.swift` (picker/badge/spinner/toast/avatar).

---

### Task 1: `AvatarImage` resize (TDD)

**Files:** Create `Places/Utilities/AvatarImage.swift`; Test `PlacesTests/AvatarImageTests.swift`.

**Interfaces:**
- Produces: `enum AvatarImage { static func jpegData(from image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.8) -> Data? }`.

- [ ] **Step 1: Write the failing test.**
```swift
import Testing
import UIKit
@testable import Places

@MainActor
struct AvatarImageTests {
    private func solidImage(_ side: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
            UIColor.systemBlue.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
    @Test func downscalesLargeImage() {
        let data = AvatarImage.jpegData(from: solidImage(1200))
        #expect(data != nil)
        let out = UIImage(data: data!)!
        #expect(max(out.size.width, out.size.height) <= 512)
    }
    @Test func keepsSmallImageWithinBound() {
        let data = AvatarImage.jpegData(from: solidImage(200))
        let out = UIImage(data: data!)!
        #expect(max(out.size.width, out.size.height) <= 512)
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.**
```swift
import UIKit

enum AvatarImage {
    /// Aspect-fit downscale to `maxDimension`, then JPEG-encode.
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.8) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: AvatarImage resize helper"`

---

### Task 2: `AvatarStoring` + `SupabaseAvatarStore`; `updateAvatarURL`

**Files:** Create `Places/Services/AvatarStore.swift`; Modify `Places/Services/ProfileRepository.swift`, `PlacesTests/Fakes/Fakes.swift`. Build-verify.

**Interfaces:**
- Produces: `protocol AvatarStoring { func uploadAvatar(_ data: Data, userID: UUID) async throws -> String }`; `struct SupabaseAvatarStore: AvatarStoring`; `ProfileProviding.updateAvatarURL(_:id:)`; test `FakeAvatarStoring`, `FakeProfileProviding.updateAvatarURL`.

- [ ] **Step 1: `AvatarStore.swift`.**
```swift
import Foundation
import Supabase

protocol AvatarStoring {
    /// Uploads JPEG data to avatars/<uid>/<uuid>.jpg, returns the public URL string.
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String
}

struct SupabaseAvatarStore: AvatarStoring {
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String {
        // Folder must be the lowercased uid to match the owner-write RLS (auth.uid()::text).
        let path = "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        let bucket = SupabaseService.client.storage.from("avatars")
        try await bucket.upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        return try bucket.getPublicURL(path: path).absoluteString
    }
}
```
- [ ] **Step 2: `ProfileProviding` + `ProfileRepository`.** Add to the protocol:
```swift
    func updateAvatarURL(_ url: String, id: UUID) async throws
```
Impl in `ProfileRepository`:
```swift
    func updateAvatarURL(_ url: String, id: UUID) async throws {
        try await SupabaseService.client.from("profiles")
            .update(["avatar_url": url]).eq("id", value: id.uuidString).execute()
    }
```
- [ ] **Step 3: Fakes** (`Fakes.swift`). Add to `FakeProfileProviding`:
```swift
    func updateAvatarURL(_ url: String, id: UUID) async throws { stored.avatarURL = url }
```
Add a fake avatar store:
```swift
final class FakeAvatarStoring: AvatarStoring {
    var returnURL = "https://cdn.example/avatar.jpg"
    var shouldThrow = false
    private(set) var uploadCount = 0
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String {
        uploadCount += 1
        if shouldThrow { throw URLError(.badServerResponse) }
        return returnURL
    }
}
```
- [ ] **Step 4: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED. (If `upload`/`getPublicURL`/`FileOptions` labels differ in 2.54, adjust to the compiler-reported names — calls are stable.)
- [ ] **Step 5: Commit.** `git commit -am "feat: AvatarStoring + updateAvatarURL"`

---

### Task 3: `SessionStore.updateAvatar` (TDD)

**Files:** Modify `Places/View Models/SessionStore.swift`, `PlacesTests/SessionStoreTests.swift`; Test `PlacesTests/AvatarUpdateTests.swift`.

**Interfaces:**
- Consumes: `AvatarStoring`, `ProfileProviding.updateAvatarURL`.
- Produces: `SessionStore.init(auth:profiles:avatars:defaults:)`; `func updateAvatar(jpegData: Data) async throws`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

@MainActor
struct AvatarUpdateTests {
    private func makeStore(avatarThrows: Bool = false)
        -> (SessionStore, FakeProfileProviding, FakeAvatarStoring) {
        let id = UUID()
        let auth = FakeAuthProviding(); auth.restoreID = id
        let repo = FakeProfileProviding(stored: .fixture(onboardingComplete: true))
        let avatars = FakeAvatarStoring(); avatars.shouldThrow = avatarThrows
        let store = SessionStore(auth: auth, profiles: repo, avatars: avatars,
                                 defaults: UserDefaults(suiteName: "t-\(UUID().uuidString)")!)
        return (store, repo, avatars)
    }

    @Test func successStoresURL() async throws {
        let (store, repo, avatars) = makeStore()
        await store.bootstrap()
        try await store.updateAvatar(jpegData: Data([1, 2, 3]))
        #expect(store.currentProfile?.avatarURL == avatars.returnURL)
        #expect(repo.stored.avatarURL == avatars.returnURL)
    }

    @Test func uploadFailureThrowsAndLeavesAvatarUnchanged() async {
        let (store, _, _) = makeStore(avatarThrows: true)
        await store.bootstrap()
        await #expect(throws: (any Error).self) {
            try await store.updateAvatar(jpegData: Data([1]))
        }
        #expect(store.currentProfile?.avatarURL == nil)
    }
}
```
- [ ] **Step 2: Run — expect fail** (extra init arg / no `updateAvatar`).
- [ ] **Step 3: Implement.** In `SessionStore`, add the stored dep + init param + method:
```swift
    private let avatars: AvatarStoring

    init(auth: AuthProviding, profiles: ProfileProviding, avatars: AvatarStoring, defaults: UserDefaults = .standard) {
        self.auth = auth
        self.profiles = profiles
        self.avatars = avatars
        self.defaults = defaults
    }

    func updateAvatar(jpegData: Data) async throws {
        guard let id = userID else { return }
        let url = try await avatars.uploadAvatar(jpegData, userID: id)
        try await profiles.updateAvatarURL(url, id: id)
        currentProfile?.avatarURL = url
    }
```
- [ ] **Step 4: Fix the existing `SessionStoreTests.makeStore`** — add `avatars: FakeAvatarStoring()` to its `SessionStore(...)` call.
- [ ] **Step 5: Run — expect pass** (new + existing tests).
- [ ] **Step 6: Commit.** `git commit -am "feat: SessionStore.updateAvatar"`

---

### Task 4: `ProfileHeader` picker + injection

**Files:** Modify `Places/App/PlacesApp.swift`, `Places/Components/ProfileHeader.swift`. Interactive verify.

- [ ] **Step 1: Inject the store** in `PlacesApp`: change the `SessionStore(...)` construction to include `avatars: SupabaseAvatarStore()`.
- [ ] **Step 2: ProfileHeader state + picker.** Add:
```swift
import PhotosUI
// …
@State private var pickedItem: PhotosPickerItem?
@State private var isUploading = false
@State private var toast: ToastData?
```
Replace the avatar `Image("profile")` in `LogoView` with an avatar that prefers the remote URL, wrapped in a `PhotosPicker` + camera badge:
```swift
private func avatarContent() -> some View {
    Group {
        if let url = session?.currentProfile?.avatarURL, !url.isEmpty {
            RemoteImage(url, width: 200, height: 200)
        } else {
            Image("profile").resizable().aspectRatio(contentMode: .fit)
        }
    }
}
```
Wrap it:
```swift
PhotosPicker(selection: $pickedItem, matching: .images) {
    avatarContent()
        .frame(height: isLargerHeader ? 200 : 55)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(6)
                .background(Circle().fill(Color.accentColor))
                .opacity(isLargerHeader ? 1 : 0)   // badge only in the expanded header
        }
        .overlay { if isUploading { Circle().fill(.black.opacity(0.35)); ProgressView().tint(.white) } }
}
.buttonStyle(.plain)
.disabled(isUploading)
```
- [ ] **Step 3: Handle the pick** — add `.onChange(of: pickedItem)` on the header body and `.toast($toast)`:
```swift
.onChange(of: pickedItem) { _, item in
    guard let item else { return }
    Task {
        isUploading = true
        defer { isUploading = false; pickedItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = AvatarImage.jpegData(from: image) else {
                toast = ToastData(message: "Couldn't read that photo.", isError: true); return
            }
            try await session?.updateAvatar(jpegData: jpeg)
        } catch {
            toast = ToastData(message: "Couldn't update photo. Please try again.", isError: true)
        }
    }
}
.toast($toast)
```
(`ProfileHeader` already reads `@Environment(SessionStore.self) private var session`.)
- [ ] **Step 4: Interactive verify** on iPhone 17 Pro (signed in): tap the avatar → pick a photo → spinner → avatar updates and persists across relaunch; check `select avatar_url from profiles where id = '<uid>'`; force an error (airplane mode) → toast, avatar unchanged.
- [ ] **Step 5: Commit.** `git commit -am "feat: profile photo picker in ProfileHeader"`

---

## Deferred (out of scope)
Cropping/editing UI; removing an avatar; old-file cleanup; avatar display outside the profile header.
