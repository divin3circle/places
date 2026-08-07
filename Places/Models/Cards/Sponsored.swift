//
// Sponsored.swift
// Places
// Created by Sylus Abel on 06/08/2026
//

import Foundation
import SwiftUI

struct Sponsored: Identifiable {
  var id: UUID = .init()
  var image: String
  /// Brand tint. Used for the "Sponsored" badge and as the base fill shown behind
  /// the photo while `DownsampledAssetImage` decodes (avoids a grey flash mid-morph).
  var accentColor: Color
  var offset: CGFloat = 0
  /// Placement kind, e.g. "Food Joint" / "Car Rental" / "Tour Guide".
  var category: String
  var title: String
  /// Tagline on the card; reused as the description in the expanded detail.
  var subtitle: String
  /// Human-readable place, e.g. "Kileleshwa, Nairobi".
  var location: String
  /// Primary call-to-action label, e.g. "Get Directions" / "Book a Car".
  var ctaLabel: String
}
