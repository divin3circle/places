//
//  TripView.swift
//  Places
//
//  Full-screen detail for a saved itinerary. A non-interactive map of the trip's
//  stops sits behind a pull-up sheet that holds the day-by-day plan; a floating
//  bar carries close + share. Place coordinates/imagery are re-resolved on appear
//  via the grounding layer (see TripViewModel).
//

import SwiftUI
import MapKit
import SwiftData
import SwiftfulRouting

struct TripView: View {
    @Environment(\.router) private var router
    @Environment(\.modelContext) private var context

    @State private var vm: TripViewModel
    @State private var appeared = false
    @State private var showDeleteConfirm = false
    @State private var showEditor = false

    init(trip: SavedTrip) {
        _vm = State(initialValue: TripViewModel(trip: trip))
    }

    var body: some View {
        TripContentScrollView { progress in
            heroBackdrop(progress: progress)
        } sheetContent: { _ in
            detailSheet
        } bottomBar: { progress in
            bottomBar
                .padding(.bottom, 10)
                // Fade + disable as the sheet rises over it (issue: unclickable when open).
                .opacity(1 - min(progress * 1.6, 1))
                .allowsHitTesting(progress < 0.4)
        }
        .task {
            await vm.resolvePlaces()
            withAnimation(.snappy(duration: 0.45)) { appeared = true }
        }
        .confirmationDialog("Delete this trip?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteTrip() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \u{201C}\(vm.title)\u{201D} from My Trips. This can't be undone.")
        }
        .fullScreenCover(isPresented: $showEditor, onDismiss: {
            // The trip may have been edited in the chat — rebuild from its latest version.
            let trip = vm.trip
            vm = TripViewModel(trip: trip)
            appeared = false
            Task {
                await vm.resolvePlaces()
                withAnimation(.snappy(duration: 0.45)) { appeared = true }
            }
        }) {
            GenerateItineraryView(trip: vm.trip)
        }
    }

    // MARK: Hero (behind the sheet) — map of stops, or the cover as a fallback

    @ViewBuilder
    private func heroBackdrop(progress: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            if !vm.resolvedPlaces.isEmpty {
                Map(interactionModes: []) {
                    ForEach(vm.resolvedPlaces) { place in
                        Marker(place.name, coordinate: place.coordinate)
                    }
                }
            } else {
                RemoteImage(vm.coverImage, width: 500, height: 700)
            }

            // Subtle bottom scrim so the floating bar reads over any map region.
            // Title/meta live on the sheet header — the map stays clean.
            LinearGradient(colors: [.clear, .black.opacity(0.28)],
                           startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)
        }
        .containerRelativeFrame(.vertical)
        .frame(maxWidth: .infinity)
    }

    // MARK: Detail sheet — the plan

    private var detailSheet: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Peek header
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .lineLimit(2)
                Text(vm.metaLine)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Button {
                showEditor = true
            } label: {
                Label("Edit with AI", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.appPrimary)

            if !vm.summary.isEmpty {
                Text(vm.summary)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if !vm.rationale.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(vm.rationale)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(vm.days.enumerated()), id: \.offset) { index, day in
                daySection(index: index, day: day)
                    // Subtle staggered reveal on first load.
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.snappy(duration: 0.4).delay(Double(index) * 0.05), value: appeared)
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .padding(.bottom, 40)
    }

    private func daySection(index: Int, day: ItineraryDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(index + 1)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(day.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            if !day.subtitle.isEmpty {
                Text(day.subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(day.activities.enumerated()), id: \.offset) { _, activity in
                activityRow(activity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func activityRow(_ activity: ItineraryActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.kind.symbolName)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                if !activity.description.isEmpty {
                    Text(activity.description)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if !activity.placeName.isEmpty, let place = vm.registry.resolve(activity.placeName) {
                    RemoteImage(place.imageURL?.absoluteString ?? place.imageName ?? "sample", width: 320, height: 140)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 12, style: .continuous))
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: vm.resolvedPlaces.count)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack(spacing: 10) {
                Label("Created \(vm.createdLabel)", systemImage: "calendar")
                if vm.editCount > 0 {
                    Text("· Edited \(vm.editCount)×")
                }
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete trip", systemImage: "trash")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.top, 4)
    }

    // MARK: Floating bar — close + share

    private var bottomBar: some View {
        Text("Trip Details")
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(.ultraThinMaterial, in: .capsule)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                HStack {
                    Button {
                        router.dismissScreen()
                    } label: {
                        circleIcon("xmark")
                    }
                    .buttonStyle(PressableButtonStyle())

                    Spacer()

                    ShareLink(item: vm.shareText) {
                        circleIcon("square.and.arrow.up")
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, 15)
            }
    }

    private func circleIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .frame(width: 45, height: 45)
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial, in: .circle)
    }

    // MARK: Actions

    private func deleteTrip() {
        for version in vm.trip.versions { context.delete(version) }
        context.delete(vm.trip)
        try? context.save()
        router.dismissScreen()
    }
}
