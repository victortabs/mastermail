import Foundation

/// Guarda os tokens num arquivo com permissão 0600 em Application Support (ADR 0007: sem Keychain).
public struct TokenStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    /// `~/Library/Application Support/MasterMail/tokens.json`
    public static func `default`() -> TokenStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return TokenStore(fileURL: base.appendingPathComponent("MasterMail/tokens.json"))
    }

    public func load() -> Tokens? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Tokens.self, from: data)
    }

    public func save(_ tokens: Tokens) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(tokens).write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
