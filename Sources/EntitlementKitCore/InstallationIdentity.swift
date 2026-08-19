import Foundation

public protocol InstallationIdentifying: Sendable {
    func appUserID() -> String
}

/// Persists one opaque UUID per installation. Use a Keychain-backed implementation
/// in apps that need identity to survive an uninstall.
public final class UserDefaultsInstallationIdentity: InstallationIdentifying, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String) {
        self.defaults = defaults
        self.key = key
    }

    public func appUserID() -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        defaults.set(generated, forKey: key)
        return generated
    }
}
