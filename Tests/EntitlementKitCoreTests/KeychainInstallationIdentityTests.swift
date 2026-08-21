import Foundation
import Testing
@testable import EntitlementKitCore

@Suite("KeychainInstallationIdentity", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil, "uses the login keychain"))
struct KeychainInstallationIdentityTests {
    private let service = "com.entitlementkit.tests"
    private func account() -> String { "test-\(UUID().uuidString)" }

    @Test func persistsAcrossInstances() {
        let key = account()
        let first = KeychainInstallationIdentity(service: service, account: key).appUserID()
        let second = KeychainInstallationIdentity(service: service, account: key).appUserID()
        #expect(first == second)
    }

    @Test func migratesLegacyIdentity() throws {
        let suite = "com.entitlementkit.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = UUID().uuidString.lowercased()
        defaults.set(legacy, forKey: "legacy")
        let migrated = KeychainInstallationIdentity(service: service, account: account(), migratingFrom: defaults, legacyKey: "legacy").appUserID()
        #expect(migrated == legacy)
    }

    @Test func replacesIdentity() throws {
        let identity = KeychainInstallationIdentity(service: service, account: account())
        let target = UUID().uuidString.lowercased()
        try identity.replaceAppUserID(target)
        #expect(identity.appUserID() == target)
    }
}
