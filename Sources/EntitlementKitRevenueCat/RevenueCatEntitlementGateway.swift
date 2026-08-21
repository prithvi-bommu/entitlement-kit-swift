import Combine
import EntitlementKitCore
import Foundation
import RevenueCat

public enum RedemptionFailure: Equatable, Sendable {
    case invalidToken
    case purchaseBelongsToOtherUser
    case expired
    case providerError
}

public enum RedemptionResult: Equatable, Sendable {
    case notRedemptionURL
    case redeemed(EntitlementStatus)
    case failed(RedemptionFailure)
}

public enum ActivationFailure: Equatable, Sendable {
    case malformedCode
    case unknownCode
    case noEntitlement
    case identityCannotPersist
    case providerError
}

public enum ActivationResult: Equatable, Sendable {
    case activated(EntitlementStatus)
    case failed(ActivationFailure)
}

@MainActor
public final class RevenueCatEntitlementGateway: ObservableObject {
    @Published public private(set) var status: EntitlementStatus = .free

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

    public func redeem(url: URL) async -> RedemptionResult {
        guard let redemption = url.asWebPurchaseRedemption else { return .notRedemptionURL }
        let result = await Purchases.shared.redeemWebPurchase(redemption)
        switch result {
        case .success(let info):
            updateStatus(map(info))
            return .redeemed(status)
        case .invalidToken:
            return .failed(.invalidToken)
        case .purchaseBelongsToOtherUser:
            return .failed(.purchaseBelongsToOtherUser)
        case .expired:
            return .failed(.expired)
        case .error:
            return .failed(.providerError)
        }
    }

    public func activationCode() -> String? {
        ActivationCode.encode(appUserID: identity.appUserID())
    }

    /// Activates this installation with a code from another device. The adopted
    /// identity is persisted before access is reported, so it survives relaunch.
    public func activate(withCode code: String) async -> ActivationResult {
        guard let targetID = ActivationCode.decode(code) else { return .failed(.malformedCode) }
        guard Purchases.isConfigured else { return .failed(.providerError) }
        guard let updatingIdentity = identity as? any InstallationIdentityUpdating else {
            return .failed(.identityCannotPersist)
        }
        let previousID = identity.appUserID()
        do {
            let (info, created) = try await Purchases.shared.logIn(targetID)
            guard !created else { _ = try? await Purchases.shared.logIn(previousID); return .failed(.unknownCode) }
            let resolved = map(info)
            guard resolved.hasAccess else { _ = try? await Purchases.shared.logIn(previousID); return .failed(.noEntitlement) }
            do { try updatingIdentity.replaceAppUserID(targetID) }
            catch { _ = try? await Purchases.shared.logIn(previousID); return .failed(.identityCannotPersist) }
            updateStatus(resolved)
            return .activated(resolved)
        } catch { return .failed(.providerError) }
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
