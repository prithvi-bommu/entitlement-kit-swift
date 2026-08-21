import Foundation
import Testing
@testable import EntitlementKitCore

@Suite("ActivationCode")
struct ActivationCodeTests {
    private let id = "6f9619ff-8b86-d011-b42d-00cf4fc964ff"
    @Test func roundTrip() throws { let code = try #require(ActivationCode.encode(appUserID: id)); #expect(ActivationCode.decode(code) == id) }
    @Test func acceptsFormattingAndConfusables() throws {
        let code = try #require(ActivationCode.encode(appUserID: id)).replacingOccurrences(of: "-", with: "")
        #expect(ActivationCode.decode(code.lowercased()) == id)
        #expect(ActivationCode.decode(code.replacingOccurrences(of: "0", with: "O")) == id)
    }
    @Test func rejectsInvalidCodes() throws {
        let code = try #require(ActivationCode.encode(appUserID: id)).replacingOccurrences(of: "-", with: "")
        #expect(ActivationCode.decode(String(code.dropLast())) == nil)
        #expect(ActivationCode.decode("U" + code.dropFirst()) == nil)
        #expect(ActivationCode.encode(appUserID: "not-a-uuid") == nil)
    }
    @Test func randomRoundTrips() throws { for _ in 0..<100 { let value = UUID().uuidString.lowercased(); #expect(ActivationCode.decode(try #require(ActivationCode.encode(appUserID: value))) == value) } }
}
