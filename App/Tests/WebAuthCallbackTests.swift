import Foundation
import MasterMailCore
import Testing

@MainActor
struct WebAuthCallbackTests {
    @Test func callbackFromBackgroundQueueIsDeliveredOnMainActor() async throws {
        let expected = URL(string: "msauth.test://auth?code=fake&state=test")!
        let result = await withCheckedContinuation { continuation in
            let handler = WebAuth.completionHandler { result in
                MainActor.assertIsolated()
                continuation.resume(returning: result)
            }
            DispatchQueue.global().async { handler(expected, nil) }
        }
        #expect(try result.get() == expected)
    }

    @Test func missingCallbackFromBackgroundQueueReturnsErrorWithoutCrashing() async throws {
        let result = await withCheckedContinuation { continuation in
            let handler = WebAuth.completionHandler { result in
                MainActor.assertIsolated()
                continuation.resume(returning: result)
            }
            DispatchQueue.global().async { handler(nil, nil) }
        }
        guard case let .failure(error) = result else {
            Issue.record("Callback ausente deveria produzir um erro"); return
        }
        #expect(error as? OAuthError != nil)
    }
}
