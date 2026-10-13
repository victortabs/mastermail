import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Modelo local da Apple (Apple Intelligence). Gratuito e offline; janela de ~4k tokens (ADR 0004).
public struct FoundationModelsProvider: AIProvider {
    public let name = "Apple Intelligence"

    public init() {}

    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
        #else
        return false
        #endif
    }

    public func complete(system: String, user: String, maxTokens: Int) async throws -> String {
        #if canImport(FoundationModels)
        let session = LanguageModelSession(instructions: system)
        let options = GenerationOptions(temperature: 0, maximumResponseTokens: maxTokens)
        return try await session.respond(to: user, options: options).content
        #else
        throw AIError.unavailable("Foundation Models não existe neste sistema.")
        #endif
    }
}
