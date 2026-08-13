//
//  ItineraryCloudClient.swift
//  Places
//
//  The request contract + a thin URLSession client for the Supabase Edge Function
//  that proxies OpenAI. The app sends structured inputs (config, mode, allowed
//  place names, and — for edits — the current itinerary); the function owns the
//  prompt + JSON schema and returns a `GeneratedItinerary`. @MainActor so the
//  small encode/decode never crosses actors (the network still runs off-main
//  during `await`).
//

import Foundation
import Supabase

/// Body POSTed to the `generate-itinerary` Edge Function.
struct CloudItineraryRequest: Codable {
    enum Mode: String, Codable { case generate, refine }

    struct Config: Codable {
        let travelers: Int
        let hasKids: Bool
        let durationDays: Int
        let durationLabel: String
        let multipleCountries: Bool
        let expectation: String

        init(_ c: TripConfig) {
            travelers = c.travelers
            hasKids = c.hasKids
            durationDays = c.durationDays
            durationLabel = c.durationLabel
            multipleCountries = c.multipleCountries
            expectation = c.trimmedExpectation
        }
    }

    let mode: Mode
    let config: Config
    /// The only valid place names — the function grounds the model to these.
    let placeNames: [String]
    let instruction: String?          // refine only
    let current: GeneratedItinerary?  // refine only
}

@MainActor
enum ItineraryCloudClient {
    static func generate(_ request: CloudItineraryRequest) async throws -> GeneratedItinerary {
        var req = URLRequest(url: SupabaseConfig.itineraryFunctionURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        // Send the signed-in user's JWT so the function identifies the user and
        // debits their tokens. Falls back to the anon key (which the function rejects).
        let bearer = (try? await SupabaseService.client.auth.session.accessToken) ?? SupabaseConfig.anonKey
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw EngineError.unavailable("No response from the server.")
        }
        // 402 = insufficient_tokens (from the token debit) → route to the paywall.
        if http.statusCode == 402 {
            throw EngineError.paymentRequired
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw EngineError.unavailable("Server error \(http.statusCode). \(body)")
        }
        do {
            return try JSONDecoder().decode(GeneratedItinerary.self, from: data)
        } catch {
            throw EngineError.unavailable("Couldn't read the itinerary from the server.")
        }
    }
}
