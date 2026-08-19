import EntitlementKitCore
import Foundation
import Testing

@Suite("EntitlementKitIntegrationTests")
struct WebBillingFlowIntegrationTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("anonymous web checkout to offline entitlement lifecycle")
    func anonymousWebCheckoutLifecycle() {
        let defaults = UserDefaults(suiteName: "EntitlementKitIntegrationTests.lifecycle")!
        defaults.removePersistentDomain(forName: "EntitlementKitIntegrationTests.lifecycle")

        let identity = UserDefaultsInstallationIdentity(defaults: defaults, key: "installation-id")
        let statusStore = UserDefaultsEntitlementStatusStore(defaults: defaults, key: "entitlement-status")
        let billing = WebBillingConfiguration(
            purchaseLink: URL(string: "https://pay.example.com/checkout?locale=en")!,
            packageIDsByPlanID: ["annual": "$rc_annual"],
            callbackScheme: "example-revenuecat-redemption"
        )

        let appUserID = identity.appUserID()
        let checkoutURL = WebPurchaseLinkBuilder.makeURL(configuration: billing, planID: "annual")
        let checkoutItems = checkoutURL.flatMap {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems
        }

        #expect(!appUserID.isEmpty)
        #expect(checkoutItems?.contains(URLQueryItem(name: "package_id", value: "$rc_annual")) == true)
        #expect(checkoutURL?.absoluteString.contains("app_user_id") == false)

        let activeStatus = EntitlementStatus.subscribed(
            planID: "annual",
            expiresAt: now.addingTimeInterval(86_400),
            willRenew: true
        )
        statusStore.writeStatus(activeStatus)
        #expect(statusStore.readStatus()?.resolved(asOf: now).hasAccess == true)

        let expiredStatus = activeStatus.resolved(asOf: now.addingTimeInterval(86_401))
        #expect(expiredStatus == .expired(planID: "annual", expiredAt: now.addingTimeInterval(86_400)))
        #expect(!expiredStatus.hasAccess)
    }

    @Test("checkout replaces a stale package selection")
    func checkoutReplacesStalePackage() {
        let billing = WebBillingConfiguration(
            purchaseLink: URL(string: "https://pay.example.com/checkout?package_id=stale")!,
            packageIDsByPlanID: ["monthly": "$rc_monthly"],
            callbackScheme: "example-revenuecat-redemption"
        )

        let url = WebPurchaseLinkBuilder.makeURL(configuration: billing, planID: "monthly")
        let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        let packageIDs = items?.filter { $0.name == "package_id" }.map(\.value) ?? []

        #expect(packageIDs == ["$rc_monthly"])
    }
}
