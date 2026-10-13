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

/// Página de delta: além de `value`, traz o link da próxima página ou o deltaLink final.
public struct DeltaPage<Item: Decodable & Sendable>: Decodable, Sendable {
    public let value: [Item]
    public let nextLink: URL?
    public let deltaLink: URL?

    enum CodingKeys: String, CodingKey {
        case value
        case nextLink = "@odata.nextLink"
        case deltaLink = "@odata.deltaLink"
    }
}

/// Item de delta: ou uma Message completa, ou só o id com `@removed`.
public struct DeltaMessage: Decodable, Sendable {
    public let id: String
    public let removed: Bool
    public let message: Message?

    enum CodingKeys: String, CodingKey {
        case id
        case removed = "@removed"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        removed = container.contains(.removed)
        message = removed ? nil : try Message(from: decoder)
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
    public var categories: [String]?
    public var body: ItemBody?
    public var singleValueExtendedProperties: [ExtendedProperty]?

    /// Pasta local gravada na mensagem (ADR 0006), ou nil.
    public var localFolder: String? {
        let value = singleValueExtendedProperties?.first { $0.id.caseInsensitiveCompare(ExtendedProperty.localFolderID) == .orderedSame }?.value
        return (value?.isEmpty == false) ? value : nil
    }

    public static let listFields = [
        "id", "subject", "from", "toRecipients", "ccRecipients", "receivedDateTime",
        "bodyPreview", "isRead", "hasAttachments", "conversationId", "conversationIndex", "categories",
    ].joined(separator: ",")
}

/// Propriedade estendida de valor único do Graph. É como a Pasta local vive no servidor (ADR 0006).
public struct ExtendedProperty: Codable, Sendable, Hashable {
    public var id: String
    public var value: String

    /// GUID próprio do MasterMail + nome. O Outlook ignora.
    public static let localFolderID = "String {a7f3d9c0-6b2e-4c8f-9d1a-5e4b3c2d1f00} Name MasterMailFolder"
    public static let expand = "singleValueExtendedProperties($filter=id eq '\(localFolderID)')"

    public init(id: String, value: String) {
        self.id = id
        self.value = value
    }
}

/// Pasta do servidor (ver CONTEXT.md): o MasterMail lê, nunca reorganiza.
public struct MailFolder: Decodable, Sendable, Hashable, Identifiable {
    public var id: String
    public var displayName: String
    public var parentFolderId: String?
    public var childFolderCount: Int
    public var unreadItemCount: Int
    public var totalItemCount: Int
    /// Preenchido localmente: nível na árvore (0 = raiz).
    public var depth: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, displayName, parentFolderId, childFolderCount, unreadItemCount, totalItemCount
    }
}

/// Anexo (só o que precisamos para imagens inline).
public struct Attachment: Decodable, Sendable {
    public var id: String
    public var name: String?
    public var contentType: String?
    public var contentId: String?
    public var isInline: Bool?
    public var contentBytes: String?
}

public struct User: Decodable, Sendable {
    public var displayName: String?
    public var mail: String?
    public var userPrincipalName: String?
}
