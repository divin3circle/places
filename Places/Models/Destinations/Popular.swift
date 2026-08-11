//
// Popular.swift
// Places
//
// Created by Sylus Abel on 04/08/2026
//

import Foundation

struct PopularDestination: Identifiable, Hashable, Equatable {
  var id: UUID = .init()
  var image: String
  var name: String
  var rating: Double
  var bestTimeToVisit: String
  var category: String
  var previousOffset: CGFloat = 0
}
