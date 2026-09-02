import SwiftUI

struct AppRootView: View {
    @AppStorage("HasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            SubscriptionTrackerView()
        } else {
            OnboardingView(showOnboarding: Binding(
                get: { !hasSeenOnboarding },
                set: { hasSeenOnboarding = !$0 }
            ))
        }
    }
}
