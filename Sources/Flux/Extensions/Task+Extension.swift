import Foundation

extension Task where Success == Never, Failure == Never {
    
    /// Suspends the current task for at least the given duration in seconds.
    /// Throws if the task is cancelled while suspended.
    /// - Parameter seconds: The sleep duration in seconds
    static func sleep(interval: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
}
