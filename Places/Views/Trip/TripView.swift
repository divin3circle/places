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
    @State private var selectedDay = 0

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
            selectedDay = 0
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
                    ForEach(Array(vm.resolvedPlaces.enumerated()), id: \.offset) { i, place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            ZStack {
                                Circle().fill(.accent).frame(width: 26, height: 26)
                                Text("\(i + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        }
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

            if let total = vm.tripTotal {
                budgetSummary(total)
            }

            if !vm.tips.isEmpty {
                tipsSection
            }

            if !vm.days.isEmpty {
                dayTabs
                daySection(day: vm.days[min(selectedDay, vm.days.count - 1)])
                    .opacity(appeared ? 1 : 0)
                    .animation(.snappy(duration: 0.4), value: appeared)
                    .animation(.snappy, value: selectedDay)
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .padding(.bottom, 40)
    }

    // Horizontal day selector — one day's timeline shows at a time.
    private var dayTabs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(vm.days.indices, id: \.self) { i in
                    let isSelected = min(selectedDay, vm.days.count - 1) == i
                    Button {
                        withAnimation(.snappy) { selectedDay = i }
                    } label: {
                        Text("Day \(i + 1)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isSelected ? Color.primary : Color(.secondarySystemBackground), in: .capsule)
                            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func daySection(day: ItineraryDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(day.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                if !day.subtitle.isEmpty {
                    Text(day.subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if let note = day.travelNote, !note.isEmpty {
                    Label(note, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(day.activities.enumerated()), id: \.offset) { i, activity in
                    let isLast = i == day.activities.count - 1
                    timelineRow(
                        activity,
                        isLast: isLast,
                        leg: isLast ? nil : vm.leg(from: activity, to: day.activities[i + 1])
                    )
                }
            }
            if let total = vm.dayTotal(day) {
                HStack {
                    Text("Day total")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(total)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // A single timeline stop: kind-icon node + connector, then the activity.
    private func timelineRow(_ activity: ItineraryActivity, isLast: Bool, leg: TravelLeg?) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: activity.kind.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.accent)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 36)
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                if let time = vm.timeLabel(activity) {
                    Text(time)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.accent)
                }
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
                }
                if let note = activity.note, !note.isEmpty {
                    Label(note, systemImage: "lightbulb.fill")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if let price = vm.priceLabel(activity) {
                    priceChip(price).padding(.top, 2)
                }
                if let leg {
                    Label(leg.label, systemImage: leg.symbol)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, isLast ? 2 : 20)
        }
        .animation(.easeOut(duration: 0.3), value: vm.resolvedPlaces.count)
    }

    private func budgetSummary(_ total: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated budget")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(total)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            Spacer()
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundStyle(.accent)
        }
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Good to know")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            ForEach(vm.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.accent)
                        .padding(.top, 1)
                    Text(tip)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func priceChip(_ price: String) -> some View {
        let isFree = price == "Free"
        return Text(price)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background((isFree ? Color.green : Color.accentColor).opacity(0.14), in: .capsule)
            .foregroundStyle(isFree ? Color.green : Color.accentColor)
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
