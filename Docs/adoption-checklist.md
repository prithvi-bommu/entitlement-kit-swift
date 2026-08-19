# Adoption checklist

- [ ] Confirm that this product permits unlimited-device redemption.
- [ ] Define plan IDs, package IDs, and entitlement ID for this project.
- [ ] Configure RevenueCat Web Billing, offering, and Web Purchase Link.
- [ ] Enable Redemption Links in sandbox.
- [ ] Register the dashboard-generated callback scheme in the app target.
- [ ] Add `.onOpenURL` forwarding to the RevenueCat gateway.
- [ ] Verify checkout, redemption, renewal, cancellation, grace period, and expiry in sandbox.
- [ ] Verify offline launch with a valid cached status and an expired cached status.
- [ ] Use an `appl_` public SDK key for production and never commit a RevenueCat REST secret.
