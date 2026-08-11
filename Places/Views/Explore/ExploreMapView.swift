//
//  ExploreMapView.swift
//  Places
//
//  Full-screen map browse: every destination + experience as a pin, with a
//  bottom carousel synced to the map. Tapping a pin selects its card (and vice
//  versa); "View details" pushes the rich detail. (Viator/Grab-style.)
//

import SwiftUI
import MapKit
import SwiftfulRouting

struct ExploreMapView: View {
    @Environment(\.router) private var router

    @State private var vm = ExploreMapViewModel()
    @State private var camera: MapCameraPosition = .region(Self.eastAfrica)
    @State private var selectedID: String?

    /// Rough East-Africa framing until places load.
    private static let eastAfrica = MKCoordinateRegion(
        center: .init(latitude: -1.0, longitude: 36.5),
        span: .init(latitudeDelta: 9, longitudeDelta: 9)
    )

    var body: some View {
        Map(position: $camera, selection: $selectedID) {
            ForEach(vm.places) { place in
                Marker(place.name, systemImage: place.isExperience ? "figure.walk" : "mappin",
                       coordinate: place.coordinate)
                    .tint(place.isExperience ? .orange : .accentColor)
                    .tag(place.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { backButton }
        .overlay(alignment: .bottom) { carousel }
        .task { await vm.load() }
        .onChange(of: selectedID) { _, id in focus(id) }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Back

    private var backButton: some View {
        Button { router.dismissScreen() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.leading, 16)
        .padding(.top, 8)
    }

    // MARK: Carousel synced with the map

    @ViewBuilder
    private var carousel: some View {
        if !vm.places.isEmpty {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(vm.places) { place in
                            mapCard(place)
                                .id(place.id)
                                .onTapGesture { selectedID = place.id }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .onChange(of: selectedID) { _, id in
                    guard let id else { return }
                    withAnimation(.snappy) { proxy.scrollTo(id, anchor: .center) }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func mapCard(_ place: MapPlace) -> some View {
        HStack(spacing: 12) {
            RemoteImage(place.imageURL, width: 76, height: 76)
                .frame(width: 76, height: 76)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                Text(place.subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Button {
                    openDetail(place)
                } label: {
                    Text("View details")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, 1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 280)
        .background(.regularMaterial, in: .rect(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selectedID == place.id ? Color.accentColor : .clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    // MARK: Actions

    private func focus(_ id: String?) {
        guard let id, let place = vm.places.first(where: { $0.id == id }) else { return }
        withAnimation(.snappy) {
            camera = .region(MKCoordinateRegion(
                center: place.coordinate,
                span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)))
        }
    }

    private func openDetail(_ place: MapPlace) {
        if let d = place.destination {
            router.showScreen(.push) { _ in DestinationDetailView(destination: d) }
        } else if let e = place.experience {
            router.showScreen(.push) { _ in ExperienceDetailView(experience: Experience(dto: e)) }
        }
    }
}
