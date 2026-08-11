# Profile Photo Picker — Design Spec

**Date:** 2026-08-09
**App:** Places (iOS 26.5, SwiftUI, Swift 6, `-default-isolation=MainActor`)
**Depends on:** auth phase (`SessionStore`, `Profile.avatarURL`, `ProfileRepository`), `RemoteImage`, `ToastView`, and the Supabase `avatars` bucket (public read; authenticated user writes own `<uid>/` folder).

## Goal
Let a signed-in user set a profile photo: tap the avatar → `PhotosPicker` → downscale → upload to the `avatars` bucket → persist `profiles.avatar_url` → show it in `ProfileHeader`. No photo yet → keep the bundled `Image("profile")`.

## Locked decisions
1. **Entry:** tap the avatar (with a camera edit badge).
2. **Placeholder:** the existing `"profile"` asset until a photo is uploaded.
3. **Cache-busting:** unique filename per upload (`<uid>/<uuid>.jpg`) → new URL each time, so no stale cached avatar.

## Components

### 1. `AvatarStoring` seam (Services/AvatarStore.swift)
```
protocol AvatarStoring {
    /// Uploads JPEG data to avatars/<userID>/<uuid>.jpg, returns the public URL string.
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String
}
struct SupabaseAvatarStore: AvatarStoring { … }   // client.storage.from("avatars")
```
Prod: `upload(path, data:, options: FileOptions(contentType: "image/jpeg"))` then `getPublicURL(path:)`. Fake for tests.

### 2. `ProfileProviding.updateAvatarURL(_:id:)` + `ProfileRepository` impl
PostgREST `update(["avatar_url": url]).eq("id", …)`.

### 3. `AvatarImage` resize helper (Utilities/AvatarImage.swift)
`static func jpegData(from image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.8) -> Data?` — aspect-fit downscale (`UIGraphicsImageRenderer`) → `jpegData(compressionQuality:)`.

### 4. `SessionStore` — avatar dependency + method
Add `avatars: AvatarStoring` to `init`. New:
```
func updateAvatar(jpegData: Data) async throws {
    guard let id = userID else { return }
    let url = try await avatars.uploadAvatar(jpegData, userID: id)
    try await profiles.updateAvatarURL(url, id: id)
    currentProfile?.avatarURL = url   // only on success
}
```
`PlacesApp` injects `SupabaseAvatarStore()`.

### 5. `ProfileHeader` — picker + badge + states
- Avatar = `RemoteImage(url)` when `session?.currentProfile?.avatarURL` is non-nil, else `Image("profile")`.
- Wrap the avatar in a `PhotosPicker(selection:matching:.images)` with a small **camera edit badge** overlay.
- `@State private var pickedItem: PhotosPickerItem?`, `@State private var isUploading = false`, `@State private var toast: ToastData?`.
- `.onChange(of: pickedItem)`: load `Data` → `UIImage` → `AvatarImage.jpegData` → `Task { isUploading = true; defer isUploading=false; try await session?.updateAvatar(jpegData:) } catch → toast`.
- While `isUploading`: spinner over the avatar, picker disabled. `.toast($toast)`.

## Storage path & RLS
`avatars/<uid>/<uuid>.jpg`. The authenticated session token satisfies the owner-write RLS on the `<uid>/` prefix. Public read → the returned public URL renders via `RemoteImage`/`WebImage`. Old files accumulate (cleanup deferred).

## Error handling
Pick/decode failure or upload failure → toast ("Couldn't update photo"), avatar unchanged. `avatar_url` is written only after a successful upload (no optimistic mutation).

## Testing (Swift Testing)
`SessionStore.updateAvatar` via a fake `AvatarStoring` + fake `ProfileProviding`:
- success → returned URL stored in `currentProfile.avatarURL` and `updateAvatarURL` called;
- upload throw → method throws, `avatarURL` unchanged.
(Update the existing `SessionStore(...)` test constructor to pass a fake avatar store.)

## Scope
**In:** `AvatarStoring` + `SupabaseAvatarStore`, `updateAvatarURL`, `AvatarImage` resize, `SessionStore.updateAvatar` (+ injected dep), `ProfileHeader` picker/badge/spinner/toast, tests.
**Out:** cropping/editing UI, removing an avatar, old-file cleanup, avatar display outside the profile header.
