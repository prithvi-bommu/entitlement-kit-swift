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

/// Stores an opaque UUID in the device-only login keychain. Supply the prior
/// UserDefaults key when migrating an existing host so active users retain
/// their RevenueCat identity.
public final class KeychainInstallationIdentity: InstallationIdentityUpdating, @unchecked Sendable {
    private let service: String
    private let account: String
    private let legacyDefaults: UserDefaults?
    private let legacyKey: String?
    private let lock = NSLock()
    private var cached: String?

    public init(
        service: String,
        account: String,
        migratingFrom legacyDefaults: UserDefaults? = nil,
        legacyKey: String? = nil
    ) {
        self.service = service
        self.account = account
        self.legacyDefaults = legacyDefaults
        self.legacyKey = legacyKey
    }

    public func appUserID() -> String {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let data = read(), let value = String(data: data, encoding: .utf8), !value.isEmpty {
            cached = value
            return value
        }
        let value = legacyDefaults?.string(forKey: legacyKey ?? "") ?? UUID().uuidString.lowercased()
        guard !value.isEmpty, write(value) else { return UUID().uuidString.lowercased() }
        cached = value
        return value
    }

    public func replaceAppUserID(_ appUserID: String) throws {
        guard UUID(uuidString: appUserID) != nil else { throw IdentityError.invalidID }
        guard write(appUserID) else { throw IdentityError.storageFailed }
        lock.lock()
        cached = appUserID
        lock.unlock()
    }

    private func read() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess ? result as? Data : nil
    }

    private func write(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    private func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    public enum IdentityError: Error { case invalidID, storageFailed }
}
