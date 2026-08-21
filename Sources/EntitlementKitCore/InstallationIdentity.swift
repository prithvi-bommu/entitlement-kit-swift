import Foundation
import Security

public protocol InstallationIdentifying: Sendable {
    func appUserID() -> String
}

/// An installation identity that can safely adopt a verified cross-device ID.
public protocol InstallationIdentityUpdating: InstallationIdentifying {
    func replaceAppUserID(_ appUserID: String) throws
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

extension UserDefaultsInstallationIdentity: InstallationIdentityUpdating {
    public func replaceAppUserID(_ appUserID: String) throws { defaults.set(appUserID, forKey: key) }
}

/// Stores an opaque UUID in the device-only login keychain.
public final class KeychainInstallationIdentity: InstallationIdentityUpdating, @unchecked Sendable {
    private let service: String, account: String
    private let lock = NSLock()
    private var cached: String?
    public init(service: String, account: String) { self.service = service; self.account = account }
    public func appUserID() -> String {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let data = read(), let value = String(data: data, encoding: .utf8), !value.isEmpty { cached = value; return value }
        let value = UUID().uuidString.lowercased(); try? replaceAppUserID(value); cached = value; return value
    }
    public func replaceAppUserID(_ appUserID: String) throws {
        guard UUID(uuidString: appUserID) != nil, let data = appUserID.data(using: .utf8) else { throw IdentityError.invalidID }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        var item = query; item[kSecValueData as String] = data; item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw IdentityError.storageFailed }
        lock.lock(); cached = appUserID; lock.unlock()
    }
    private func read() -> Data? { var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]; var result: CFTypeRef?; return SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess ? result as? Data : nil }
    public enum IdentityError: Error { case invalidID, storageFailed }
}
