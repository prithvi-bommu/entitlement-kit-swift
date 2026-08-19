import EntitlementKitCore
import SwiftUI

public struct EntitlementPaywall: View {
    private let plans: [EntitlementPlan]
    private let onSelect: (EntitlementPlan) -> Void

    public init(plans: [EntitlementPlan], onSelect: @escaping (EntitlementPlan) -> Void) {
        self.plans = plans
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upgrade")
                .font(.title.bold())
            ForEach(plans) { plan in
                Button(plan.displayName) { onSelect(plan) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
