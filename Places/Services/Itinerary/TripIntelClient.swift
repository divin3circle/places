//
//  TripIntelClient.swift
//  Places
//
//  Thin client for the `trip-intel` Edge Function — a trip-context "tool" the app
//  plugs into generation. Static payload today; the contract lets us swap in real
//  dynamic sources (weather/FX) later without app changes.
//

import Foundation

struct TripIntel: Codable {
    let destination: String
    let weatherSummary: String
    let gettingAround: String
    let currencyTips: String
    let priceLevel: String
    let bestTime: String

    /// A compact one-liner to fold into the generation prompt.
    var promptContext: String {
        "Local context — weather: \(weatherSummary) Getting around: \(gettingAround) Money: \(currencyTips)"
    }
}

@MainActor
enum TripIntelClient {
    private struct Request: Codable { let destination: String; let month: String? }

    static func fetch(destination: String, month: String?) async throws -> TripIntel {
        var req = URLRequest(url: SupabaseConfig.tripIntelFunctionURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(Request(destination: destination, month: month))

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw EngineError.unavailable("trip-intel unavailable")
        }
        return try JSONDecoder().decode(TripIntel.self, from: data)
    }
}
