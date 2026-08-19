import Foundation

public struct WebBillingConfiguration: Sendable {
    public let purchaseLink: URL
    public let packageIDsByPlanID: [String: String]
    public let callbackScheme: String

    public init(purchaseLink: URL, packageIDsByPlanID: [String: String], callbackScheme: String) {
        self.purchaseLink = purchaseLink
        self.packageIDsByPlanID = packageIDsByPlanID
        self.callbackScheme = callbackScheme
    }
}

public enum WebPurchaseLinkBuilder {
    /// Builds an anonymous RevenueCat Web Purchase Link. The purchase is joined to
    /// the local installation only after the customer redeems its callback link.
    public static func makeURL(
        configuration: WebBillingConfiguration,
        planID: String
    ) -> URL? {
        guard let packageID = configuration.packageIDsByPlanID[planID] else { return nil }
        guard var components = URLComponents(url: configuration.purchaseLink, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "package_id" }
        items.append(URLQueryItem(name: "package_id", value: packageID))
        components.queryItems = items
        return components.url
    }
}
