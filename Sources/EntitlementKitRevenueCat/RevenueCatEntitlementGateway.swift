import EntitlementKitCore
import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
public final class RevenueCatEntitlementGateway {
    public private(set) var status: EntitlementStatus = .free

    private let apiKey: String
    private let entitlementID: String
    private let lifetimePlanIDs: Set<String>
    private let identity: any InstallationIdentifying
    private let statusStore: (any EntitlementStatusStoring)?
    private var listenerTask: Task<Void, Never>?

    public init(
        apiKey: String,
        entitlementID: String,
        lifetimePlanIDs: Set<String> = [],
        identity: any InstallationIdentifying,
        statusStore: (any EntitlementStatusStoring)? = nil
    ) {
        self.apiKey = apiKey
        self.entitlementID = entitlementID
        self.lifetimePlanIDs = lifetimePlanIDs
        self.identity = identity
        self.statusStore = statusStore
        self.status = statusStore?.readStatus()?.resolved() ?? .free
    }

    public func configure() async {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("YOUR_") else { return }
        Purchases.configure(withAPIKey: apiKey, appUserID: identity.appUserID())
        listenerTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard let self else { return }
                updateStatus(map(info))
            }
        }
        if let info = try? await Purchases.shared.customerInfo() {
            updateStatus(map(info))
        }
    }

    public func redeem(url: URL) async -> Bool {
        guard let redemption = url.asWebPurchaseRedemption else { return false }
        let result = await Purchases.shared.redeemWebPurchase(redemption)
        if case .success(let info) = result {
            updateStatus(map(info))
        }
        return true
    }

    private func map(_ info: CustomerInfo) -> EntitlementStatus {
        if info.nonSubscriptions.contains(where: { lifetimePlanIDs.contains($0.productIdentifier) }) {
            return .lifetime(planID: nil)
        }
        guard let entitlement = info.entitlements[entitlementID] else { return .free }
        let planID = entitlement.productIdentifier
        guard entitlement.isActive else {
            if let expiresAt = entitlement.expirationDate {
                return .expired(planID: planID, expiredAt: expiresAt)
            }
            return .free
        }
        guard let expiresAt = entitlement.expirationDate else { return .lifetime(planID: planID) }
        if entitlement.periodType == .trial { return .trial(expiresAt: expiresAt) }
        if entitlement.billingIssueDetectedAt != nil { return .grace(planID: planID, expiresAt: expiresAt) }
        return .subscribed(planID: planID, expiresAt: expiresAt, willRenew: entitlement.willRenew)
    }

    private func updateStatus(_ newStatus: EntitlementStatus) {
        status = newStatus
        statusStore?.writeStatus(newStatus)
    }
}
