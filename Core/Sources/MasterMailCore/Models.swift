import Foundation

/// Página de uma coleção do Graph.
public struct GraphPage<Item: Decodable & Sendable>: Decodable, Sendable {
    public let value: [Item]
    public let nextLink: URL?

    enum CodingKeys: String, CodingKey {
        case value
        case nextLink = "@odata.nextLink"
    }
}

public struct EmailAddress: Codable, Sendable, Hashable {
    public var name: String?
    public var address: String?
}

public struct Recipient: Codable, Sendable, Hashable {
    public var emailAddress: EmailAddress
}

public struct ItemBody: Codable, Sendable, Hashable {
    public var contentType: String
    public var content: String
}

/// Uma Mensagem (ver CONTEXT.md): um e-mail individual, recebido ou enviado.
public struct Message: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var subject: String?
    public var from: Recipient?
    public var toRecipients: [Recipient]?
    public var ccRecipients: [Recipient]?
    public var receivedDateTime: Date
    public var bodyPreview: String?
    public var isRead: Bool
    public var hasAttachments: Bool
    public var conversationId: String?
    public var conversationIndex: String?
    public var body: ItemBody?

    public static let listFields = [
        "id", "subject", "from", "toRecipients", "ccRecipients", "receivedDateTime",
        "bodyPreview", "isRead", "hasAttachments", "conversationId", "conversationIndex",
    ].joined(separator: ",")
}

public struct User: Decodable, Sendable {
    public var displayName: String?
    public var mail: String?
    public var userPrincipalName: String?
}
