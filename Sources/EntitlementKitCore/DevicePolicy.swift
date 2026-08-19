import Foundation

public enum DevicePolicy: Equatable, Sendable {
    case unlimited
    case serverEnforced(maximumDevices: Int)
}

public enum DeviceActivationDecision: Equatable, Sendable {
    case allowed
    case denied(reason: String)
}

/// A server-side policy is required to enforce a device maximum securely.
public protocol DeviceActivationAuthorizing: Sendable {
    func authorizeActivation(
        appUserID: String,
        entitlementID: String,
        maximumDevices: Int
    ) async throws -> DeviceActivationDecision
}
