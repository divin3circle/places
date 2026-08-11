import SwiftUI

nonisolated struct TravelInterest: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let icon: String
    /// One of the 8 `experience_categories` tags. Drives For You later.
    let categoryTag: String
}

let EastAfricaInterestsDataset: [TravelInterest] = [
    // wildlife_safaris
    TravelInterest(label: "Safari", icon: "arrow.left.arrow.right.circle.fill", categoryTag: "wildlife_safaris"),
    TravelInterest(label: "Wildlife", icon: "laurel.leading", categoryTag: "wildlife_safaris"),
    TravelInterest(label: "Camera", icon: "camera.fill", categoryTag: "wildlife_safaris"),
    // nature_hiking
    TravelInterest(label: "Hiking", icon: "figure.hiking", categoryTag: "nature_hiking"),
    TravelInterest(label: "Nature", icon: "tree.fill", categoryTag: "nature_hiking"),
    TravelInterest(label: "Trekking", icon: "leaf.fill", categoryTag: "nature_hiking"),
    // cultural_heritage
    TravelInterest(label: "History", icon: "building.columns.fill", categoryTag: "cultural_heritage"),
    TravelInterest(label: "Wander", icon: "person.fill", categoryTag: "cultural_heritage"),
    // food_coffee_tours
    TravelInterest(label: "Cuisine", icon: "cup.and.saucer.fill", categoryTag: "food_coffee_tours"),
    TravelInterest(label: "Coffee", icon: "mug.fill", categoryTag: "food_coffee_tours"),
    // arts_crafts
    TravelInterest(label: "Culture", icon: "paintpalette.fill", categoryTag: "arts_crafts"),
    // adventure_sports
    TravelInterest(label: "Camping", icon: "tent.fill", categoryTag: "adventure_sports"),
    TravelInterest(label: "Adventure", icon: "figure.climbing", categoryTag: "adventure_sports"),
    // wellness_relaxation
    TravelInterest(label: "Beaches", icon: "sun.max.fill", categoryTag: "wellness_relaxation"),
    TravelInterest(label: "Sunset", icon: "sunset.fill", categoryTag: "wellness_relaxation"),
    TravelInterest(label: "Lodges", icon: "crown.fill", categoryTag: "wellness_relaxation"),
    // nightlife_music
    TravelInterest(label: "Nightlife", icon: "music.note", categoryTag: "nightlife_music"),
]

/// Deduped, sorted category tags for a set of selected interest chips.
func categoryTags(for selected: Set<TravelInterest>) -> [String] {
    Array(Set(selected.map(\.categoryTag))).sorted()
}
