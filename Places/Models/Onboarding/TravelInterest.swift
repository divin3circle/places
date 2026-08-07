import SwiftUI

struct TravelInterest: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let icon: String
    let category: String
}

let EastAfricaInterestsDataset: [TravelInterest] = [
    TravelInterest(label: "Safari", icon: "arrow.left.arrow.right.circle.fill", category: "wildlife_core"),
    TravelInterest(label: "Trekking", icon: "leaf.fill", category: "trekking_primates"),
    TravelInterest(label: "Wildlife", icon: "laurel.leading", category: "migration_safari"),
    TravelInterest(label: "Lodges", icon: "crown.fill", category: "luxury_premium"),
    TravelInterest(label: "Cuisine", icon: "cup.and.saucer.fill", category: "culinary_coffee"),
    TravelInterest(label: "Hiking", icon: "figure.hiking", category: "mountaineering"),
    TravelInterest(label: "Beaches", icon: "sun.max.fill", category: "coastal_relaxation"),
    TravelInterest(label: "History", icon: "building.columns.fill", category: "history_culture"),
    TravelInterest(label: "Wander", icon: "person.fill", category: "solo_travel"),
    TravelInterest(label: "Nature", icon: "tree.fill", category: "eco_conservation"),
    TravelInterest(label: "Culture", icon: "paintpalette.fill", category: "arts_culture"),
    TravelInterest(label: "Family", icon: "figure.2.and.child.holdinghands", category: "family_safari"),
    TravelInterest(label: "Camping", icon: "tent.fill", category: "adventure_camping"),
    TravelInterest(label: "Sunset", icon: "sunset.fill", category: "coastal_sunset"),
    TravelInterest(label: "Camera", icon: "camera.fill", category: "photo_safari"),
]
