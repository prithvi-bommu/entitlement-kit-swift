import Foundation

public struct EntitlementPlan: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

public enum EntitlementStatus: Codable, Equatable, Sendable {
    case free
    case trial(expiresAt: Date)
    case subscribed(planID: String, expiresAt: Date, willRenew: Bool)
    case expired(planID: String, expiredAt: Date)
    case grace(planID: String, expiresAt: Date)
    case lifetime(planID: String?)

    public var hasAccess: Bool {
        switch self {
        case .free, .expired: false
        case .trial, .subscribed, .grace, .lifetime: true
        }
    }

    public var expirationDate: Date? {
        switch self {
        case .trial(let date), .subscribed(_, let date, _), .expired(_, let date), .grace(_, let date):
            date
        case .free, .lifetime: nil
        }
    }

    /// Resolves stale cached state before it is used for offline access.
    public func resolved(asOf now: Date = Date()) -> EntitlementStatus {
        switch self {
        case .free, .expired, .lifetime:
            return self
        case .trial(let expiresAt):
            return expiresAt > now ? self : .free
        case .subscribed(let planID, let expiresAt, _), .grace(let planID, let expiresAt):
            return expiresAt > now ? self : .expired(planID: planID, expiredAt: expiresAt)
        }
    }
}

public protocol EntitlementStatusStoring: Sendable {
    func readStatus() -> EntitlementStatus?
    func writeStatus(_ status: EntitlementStatus)
}

public final class UserDefaultsEntitlementStatusStore: EntitlementStatusStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String) {
        self.defaults = defaults
        self.key = key
    }

    public func readStatus() -> EntitlementStatus? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(EntitlementStatus.self, from: data)
    }

    public func writeStatus(_ status: EntitlementStatus) {
        guard let data = try? JSONEncoder().encode(status) else { return }
        defaults.set(data, forKey: key)
    }
}
