# Places - iOS Travel Companion App

## Project Overview
**Places** is a SwiftUI iOS application serving as an AI-powered travel companion for planning, sharing, and exploring destinations. Built with modern SwiftUI patterns and SwiftfulRouting for navigation.

### Tech Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI (iOS 17+)
- **Navigation**: SwiftfulRouting
- **Animations**: Lottie + Custom MicroAnimations
- **Architecture**: MVVM with Environment-based dependency injection

---

## Project Structure

```
Places/
├── App/
│   └── PlacesApp.swift           # App entry point with RouterView
├── Views/
│   ├── ContentView.swift         # Root view → Auth onboarding
│   ├── Tabs/
│   │   ├── AppTab.swift          # Main tab container with CustomTabBar
│   │   └── HomeTab.swift         # Home feed with scrollable header
│   └── Onboarding/
│       ├── Auth.swift            # Initial onboarding carousel + auth
│       ├── FirstOnboarding.swift # Feature showcase (step 1/4)
│       ├── SecondOnboarding.swift
│       ├── ThirdOnboarding.swift
│       ├── FourthOnboarding.swift
│       └── NotifiationsOnboarding.swift
├── Components/
│   ├── CustomTabBar.swift        # Glass-effect capsule tab bar
│   ├── HomeHeader.swift          # Collapsible home header
│   ├── OnboardingInfoCard.swift  # Onboarding page card
│   ├── LottieAnimationLoader.swift
│   ├── ProgressViewer.swift      # Step indicator
│   ├── PrimaryButton.swift       # Styled CTA button
│   ├── FeatureItem.swift         # Feature list item
│   ├── InterestChip.swift        # Interest selection chip
│   ├── GravityContainer.swift    # Physics-based layout
│   ├── DestinationTransition.swift
│   ├── MicroAnimations.swift     # Staggered entrance animations
│   ├── DisappearingHeader.swift  # Scroll-away header
│   └── ImageLoader.swift         # Async image loading
├── Models/
│   ├── Tabs/Tabs.swift           # AppTabs enum (5 tabs)
│   ├── Onboarding/
│   │   ├── Features.swift        # Feature data models
│   │   └── TravelInterest.swift  # Interest categories
│   └── Destinations/Destination.swift
├── Assets.xcassets/              # Images, colors, app icons
└── Lottie Animations/
    ├── feature-animation1.json
    └── onboarding-animation.json
```

---

## Key Features Implemented

1. **Multi-step Onboarding Flow**
   - 4-page carousel with parallax images
   - Apple Sign In entry point
   - Progressive feature disclosure (4 steps)
   - Notification permission request

2. **Custom Tab Navigation**
   - 5 tabs: Home, Explore, Lounges, Wallet, Profile
   - Glass-effect capsule tab bar with spring animations
   - Scroll-linked header collapse on Home tab
   - Custom `.hideNativeTabBar()` modifier

3. **Animation System**
   - Lottie integration for complex animations
   - MicroAnimations modifier for staggered entrances
   - Spring-based transitions throughout

4. **UI Components**
   - Reusable card, button, chip components
   - Progress indicators
   - Physics-based containers (GravityContainer)

---

## Navigation Flow

```
PlacesApp (RouterView)
  └── ContentView
        └── Auth (Onboarding Carousel)
              └── FirstOnboarding (Features)
                    └── SecondOnboarding
                          └── ThirdOnboarding
                                └── FourthOnboarding
                                      └── NotifiationsOnboarding
                                            └── AppTab (Main App)
                                                  ├── HomeTab
                                                  ├── Explore
                                                  ├── Lounges
                                                  ├── Wallet
                                                  └── Profile
```

---

## Development Commands

```bash
# Build and run
xcodebuild -project Places.xcodeproj -scheme Places -destination 'platform=iOS Simulator,name=iPhone 16' build

# Open in Xcode
open Places.xcodeproj
```

---

## Coding Conventions

- **File Organization**: Feature-based grouping (Views/, Components/, Models/)
- **Naming**: PascalCase for types, camelCase for properties/methods
- **SwiftUI**: Prefer `@State`/`@Binding` over `@ObservedObject` for simple state
- **Routing**: Use `Environment(\.router)` via SwiftfulRouting
- **Animations**: Default to `.spring(response:dampingFraction:)` for natural feel
- **Previews**: Every view has `#Preview` with RouterView wrapper

---

## Known Issues / TODOs

- [ ] Explore, Lounges, Wallet, Profile tabs are placeholder Text views
- [ ] SecondOnboarding through NotifiationsOnboarding need implementation review
- [ ] No persistence layer (UserDefaults/SwiftData/CoreData) yet
- [ ] No network layer or API integration
- [ ] Accessibility audit needed
- [ ] Dark mode refinement for custom colors

---

## Change Log

### [Unreleased] - Initial AGENT.md creation
- Documented project structure and architecture
- Established coding conventions
- Listed known gaps for future work

---

## Agent Instructions

When making changes to this project:

1. **Read relevant files first** - Understand existing patterns before modifying
2. **Follow conventions** - Match existing naming, structure, and SwiftUI patterns
3. **Update this file** - Log significant changes in the Change Log section
4. **Test via Previews** - Use `#Preview` for rapid iteration
5. **Preserve animation quality** - Maintain 60fps spring animations
6. **Keep components reusable** - Extract shared UI to Components/

### Priority Areas for Enhancement
1. Complete tab implementations (Explore, Lounges, Wallet, Profile)
2. Add data persistence for user preferences/onboarding state
3. Integrate backend API for destinations, search, bookings
4. Implement proper authentication flow (Apple Sign In + backend)
5. Add unit/UI tests