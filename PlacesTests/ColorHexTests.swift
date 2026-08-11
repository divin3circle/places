import Testing
import SwiftUI
@testable import Places

struct ColorHexTests {
    @Test func validHexProducesColor() { #expect(Color(hex: "#1E88E5") != nil) }
    @Test func noHashStillParses()     { #expect(Color(hex: "1E88E5") != nil) }
    @Test func nilReturnsNil()         { #expect(Color(hex: nil) == nil) }
    @Test func garbageReturnsNil()     { #expect(Color(hex: "nope") == nil) }
}
