import Foundation

public enum WebBillingConfigurationIssue: Error, Equatable, Sendable {
    case purchaseLinkMustUseHTTPS
    case purchaseLinkMustHaveHost
    case purchaseLinkMustNotContainAppUserID
    case callbackSchemeIsEmpty
    case callbackSchemeIsInvalid
    case planIDIsEmpty
    case packageIDIsEmpty(planID: String)
}

public enum WebPurchaseLinkError: Error, Equatable, Sendable {
    case invalidConfiguration([WebBillingConfigurationIssue])
    case missingPackageID(planID: String)
    case couldNotBuildURL
}

public struct WebBillingConfiguration: Sendable {
    public let purchaseLink: URL
    public let packageIDsByPlanID: [String: String]
    public let callbackScheme: String

    public init(purchaseLink: URL, packageIDsByPlanID: [String: String], callbackScheme: String) {
        self.purchaseLink = purchaseLink
        self.packageIDsByPlanID = packageIDsByPlanID
        self.callbackScheme = callbackScheme
    }

    /// Reports deterministic, non-secret integration mistakes that can be
    /// checked locally. It cannot verify RevenueCat dashboard configuration.
    public var validationIssues: [WebBillingConfigurationIssue] {
        var issues: [WebBillingConfigurationIssue] = []

        if purchaseLink.scheme?.lowercased() != "https" {
            issues.append(.purchaseLinkMustUseHTTPS)
        }
        if purchaseLink.host?.isEmpty != false {
            issues.append(.purchaseLinkMustHaveHost)
        }
        if URLComponents(url: purchaseLink, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: {
            $0.name.caseInsensitiveCompare("app_user_id") == .orderedSame
        }) == true {
            issues.append(.purchaseLinkMustNotContainAppUserID)
        }

        if callbackScheme.isEmpty {
            issues.append(.callbackSchemeIsEmpty)
        } else if !Self.isValidCallbackScheme(callbackScheme) {
            issues.append(.callbackSchemeIsInvalid)
        }

        for planID in packageIDsByPlanID.keys.sorted() {
            guard let packageID = packageIDsByPlanID[planID] else { continue }
            if planID.isEmpty {
                issues.append(.planIDIsEmpty)
            }
            if packageID.isEmpty {
                issues.append(.packageIDIsEmpty(planID: planID))
            }
        }

        return issues
    }

    public var isValid: Bool {
        validationIssues.isEmpty
    }

    /// Returns whether an incoming URL belongs to this host app's registered
    /// callback scheme. This is routing hygiene; redemption validity remains
    /// RevenueCat's responsibility.
    public func handlesCallbackURL(_ url: URL) -> Bool {
        url.scheme?.caseInsensitiveCompare(callbackScheme) == .orderedSame
    }

    private static func isValidCallbackScheme(_ scheme: String) -> Bool {
        guard let first = scheme.unicodeScalars.first,
              CharacterSet.letters.contains(first) else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-."))
        return scheme.unicodeScalars.allSatisfy(allowed.contains)
    }
}

public enum WebPurchaseLinkBuilder {
    /// Builds an anonymous RevenueCat Web Purchase Link. The purchase is joined to
    /// the local installation only after the customer redeems its callback link.
    public static func buildURL(
        configuration: WebBillingConfiguration,
        planID: String
    ) -> Result<URL, WebPurchaseLinkError> {
        let issues = configuration.validationIssues
        guard issues.isEmpty else { return .failure(.invalidConfiguration(issues)) }
        guard let packageID = configuration.packageIDsByPlanID[planID] else {
            return .failure(.missingPackageID(planID: planID))
        }
        guard var components = URLComponents(url: configuration.purchaseLink, resolvingAgainstBaseURL: false) else {
            return .failure(.couldNotBuildURL)
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "package_id" }
        items.append(URLQueryItem(name: "package_id", value: packageID))
        components.queryItems = items
        guard let url = components.url else { return .failure(.couldNotBuildURL) }
        return .success(url)
    }

    /// Convenience wrapper that applies full configuration validation. Use
    /// `buildURL(configuration:planID:)` when the host needs to present a
    /// configuration or mapping error.
    public static func makeURL(
        configuration: WebBillingConfiguration,
        planID: String
    ) -> URL? {
        try? buildURL(configuration: configuration, planID: planID).get()
    }
}
