//
//  ItineraryMessageView.swift
//  Places
//
//  Renders a (streaming, partially-generated) itinerary as a rich assistant
//  message: title, summary, rationale, a map of the tool-resolved places, and a
//  day-by-day breakdown with activity icons + place images. Every field is
//  optional (it fills in as the model streams), guarded with `if let`.
//

import SwiftUI
import MapKit

struct ItineraryMessageView: View {
    let itinerary: ItineraryDisplay
    let registry: PlaceRegistry

    // Resolved once per streamed snapshot (not per body render) — see .onChange below.
    @State private var resolvedPlaces: [ResolvedPlace] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = itinerary.title {
                Text(title)
                    .font(.system(.title2, design: .rounded).bold())
                    .contentTransition(.opacity)
            }
            if let summary = itinerary.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            if let rationale = itinerary.rationale, !rationale.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles").font(.footnote).foregroundStyle(.secondary)
                    Text(rationale)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .contentTransition(.opacity)
            }

            if !resolvedPlaces.isEmpty {
                Map {
                    ForEach(resolvedPlaces) { place in
                        Marker(place.name, coordinate: place.coordinate)
                    }
                }
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(false)
            }

            if let days = itinerary.days {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    dayView(index: index, day: day)
                }
                .animation(.easeOut, value: itinerary)
            }

            placesCarousel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { resolvedPlaces = Self.resolve(itinerary, registry: registry) }
        .onChange(of: itinerary) { _, new in
            resolvedPlaces = Self.resolve(new, registry: registry)
        }
    }

    // Horizontal carousel of the itinerary's resolved places (reuses PlaceCard).
    @ViewBuilder
    private var placesCarousel: some View {
        if !resolvedPlaces.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Places on this trip")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 14) {
                        ForEach(resolvedPlaces) { place in
                            PlaceCard(
                                image: place.imageURL?.absoluteString ?? place.imageName ?? "sample",
                                title: place.name,
                                subtitle: place.subtitle ?? "",
                                width: 200,
                                imageHeight: 150
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.top, 4)
        }
    }

    /// Every already-named place across the days, resolved to geo/imagery. Static so
    /// it's only invoked from onAppear/onChange, never during a body render.
    private static func resolve(_ itinerary: ItineraryDisplay, registry: PlaceRegistry) -> [ResolvedPlace] {
        let names = (itinerary.days ?? [])
            .flatMap { ($0.activities ?? []).compactMap { $0.placeName } }
        var seen = Set<String>()
        var out: [ResolvedPlace] = []
        for name in names {
            if let place = registry.resolve(name), !seen.contains(place.id) {
                seen.insert(place.id)
                out.append(place)
            }
        }
        return out
    }

    private func dayView(index: Int, day: ItineraryDisplay.Day) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = day.title {
                Text("Day \(index + 1) · \(title)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .contentTransition(.opacity)
            }
            if let subtitle = day.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            if let activities = day.activities {
                ForEach(Array(activities.enumerated()), id: \.offset) { _, activity in
                    activityRow(activity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func activityRow(_ activity: ItineraryDisplay.Activity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.kind?.symbolName ?? "mappin.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                if let title = activity.title {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .contentTransition(.opacity)
                }
                if let description = activity.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                if let placeName = activity.placeName,
                   let place = registry.resolve(placeName) {
                    RemoteImage(place.imageURL?.absoluteString ?? place.imageName ?? "sample", width: 320, height: 150)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 12, style: .continuous))
                        .padding(.top, 2)
                }
            }
        }
    }
}
