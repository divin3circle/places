//
//  CreateTripView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 92, height: 92)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.accent)
            }

            VStack(spacing: 8) {
                Text("Plan a new trip")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .fontWidth(.expanded)
                Text("Let the AI concierge build a personalized itinerary for your next adventure.")
                    .font(.callout)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                PrimaryButton(title: "Start planning") { dismiss() }
                Button("Maybe later") { dismiss() }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .presentationDetents([.medium])
        .presentationBackground(.regularMaterial)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            CreateTripView()
        }
}
