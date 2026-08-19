import EntitlementKitCore
import Foundation
import Testing

@Suite("EntitlementKitCore")
struct EntitlementKitCoreTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("expired trial resolves to free")
    func expiredTrialResolves() {
        let status = EntitlementStatus.trial(expiresAt: now.addingTimeInterval(-1))
        #expect(status.resolved(asOf: now) == .free)
    }

    @Test("expired subscription retains plan")
    func expiredSubscriptionResolves() {
        let expiry = now.addingTimeInterval(-1)
        let status = EntitlementStatus.subscribed(planID: "yearly", expiresAt: expiry, willRenew: true)
        #expect(status.resolved(asOf: now) == .expired(planID: "yearly", expiredAt: expiry))
    }

    @Test("expiry boundary is not active")
    func expiryBoundaryResolves() {
        let status = EntitlementStatus.grace(planID: "monthly", expiresAt: now)
        #expect(!status.resolved(asOf: now).hasAccess)
    }

    @Test("lifetime access never expires")
    func lifetimeNeverExpires() {
        let status = EntitlementStatus.lifetime(planID: "lifetime")
        #expect(status.resolved(asOf: now) == status)
        #expect(status.hasAccess)
    }

    @Test("purchase URLs add the selected package")
    func purchaseURLIncludesPackage() {
        let configuration = WebBillingConfiguration(
            purchaseLink: URL(string: "https://pay.example.com/checkout?locale=en")!,
            packageIDsByPlanID: ["monthly": "$rc_monthly"],
            callbackScheme: "example-redemption"
        )
        let url = WebPurchaseLinkBuilder.makeURL(configuration: configuration, planID: "monthly")
        let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        #expect(items?.contains(URLQueryItem(name: "package_id", value: "$rc_monthly")) == true)
    }

    @Test("unknown plans do not create a checkout URL")
    func unknownPlanDoesNotCreateURL() {
        let configuration = WebBillingConfiguration(
            purchaseLink: URL(string: "https://pay.example.com")!,
            packageIDsByPlanID: [:],
            callbackScheme: "example-redemption"
        )
        #expect(WebPurchaseLinkBuilder.makeURL(configuration: configuration, planID: "monthly") == nil)
    }

    @Test("installation identity is stable")
    func installationIdentityIsStable() {
        let defaults = UserDefaults(suiteName: "EntitlementKitCoreTests.identity")!
        defaults.removePersistentDomain(forName: "EntitlementKitCoreTests.identity")
        let identity = UserDefaultsInstallationIdentity(defaults: defaults, key: "install-id")
        #expect(identity.appUserID() == identity.appUserID())
    }

    @Test("cached status is persisted and expiry resolved by the consumer")
    func cachedStatusRoundTrip() {
        let defaults = UserDefaults(suiteName: "EntitlementKitCoreTests.status")!
        defaults.removePersistentDomain(forName: "EntitlementKitCoreTests.status")
        let store = UserDefaultsEntitlementStatusStore(defaults: defaults, key: "status")
        store.writeStatus(.trial(expiresAt: now.addingTimeInterval(-1)))
        #expect(store.readStatus()?.resolved(asOf: now) == .free)
    }
}
