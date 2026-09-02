import SwiftData

@MainActor
enum AppModelContainer {
    // Never replace a failed persistent store with an empty in-memory store.
    static let result: Result<ModelContainer, Error> = Result {
        try ModelContainer(for: Subscription.self)
    }

    static func container() throws -> ModelContainer { try result.get() }
}
