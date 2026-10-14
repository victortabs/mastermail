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
    public let readState: Bool?
    public let needsFullMessage: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case removed = "@removed"
        case receivedDateTime, isRead, hasAttachments
    }

    private struct Field: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        removed = container.contains(.removed)
        readState = removed ? nil : try container.decodeIfPresent(Bool.self, forKey: .isRead)
        if removed {
            message = nil
            needsFullMessage = false
        } else if container.contains(.receivedDateTime), container.contains(.hasAttachments),
                  readState != nil, try !container.decodeNil(forKey: .receivedDateTime),
                  try !container.decodeNil(forKey: .hasAttachments) {
            message = try Message(from: decoder)
            needsFullMessage = false
        } else {
            // O delta também emite eventos com apenas id + isRead.
            let fields = Set(try decoder.container(keyedBy: Field.self).allKeys.map(\.stringValue))
            message = nil
            needsFullMessage = readState == nil || !fields.subtracting(["@odata.type", "id", "isRead"]).isEmpty
        }
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

    public init(contentType: String, content: String) {
        self.contentType = contentType
        self.content = content
    }
}

/// Uma Mensagem (ver CONTEXT.md): um e-mail individual, recebido ou enviado.
public struct Message: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var parentFolderId: String?
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
    public var flag: Flag?
    /// Só em mensagens de reunião: meetingRequest, meetingCancelled, meetingAccepted... (eventMessage do Graph).
    public var meetingMessageType: String?
    public var body: ItemBody?
    public var singleValueExtendedProperties: [ExtendedProperty]?

    public struct Flag: Codable, Sendable, Hashable { public var flagStatus: String? }
    public var isFlagged: Bool { flag?.flagStatus == "flagged" }

    /// Pasta local gravada na mensagem (ADR 0006), ou nil.
    public var localFolder: String? {
        let value = singleValueExtendedProperties?.first { $0.id.caseInsensitiveCompare(ExtendedProperty.localFolderID) == .orderedSame }?.value
        return (value?.isEmpty == false) ? value : nil
    }

    public static let listFields = [
        "id", "parentFolderId", "subject", "from", "toRecipients", "ccRecipients", "receivedDateTime",
        // meetingMessageType pertence a eventMessage; pedi-lo em uma coleção de message causa HTTP 400.
        "bodyPreview", "isRead", "hasAttachments", "conversationId", "conversationIndex", "categories", "flag",
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
public struct Attachment: Decodable, Sendable, Identifiable, Hashable {
    public var id: String
    public var name: String?
    public var contentType: String?
    public var contentId: String?
    public var isInline: Bool?
    public var size: Int?
    public var contentBytes: String?

    public init(id: String, name: String? = nil, contentType: String? = nil, contentId: String? = nil, isInline: Bool? = nil, size: Int? = nil, contentBytes: String? = nil) {
        self.id = id; self.name = name; self.contentType = contentType; self.contentId = contentId; self.isInline = isInline; self.size = size; self.contentBytes = contentBytes
    }
}

public struct User: Decodable, Sendable {
    public var id: String?
    public var displayName: String?
    public var mail: String?
    public var userPrincipalName: String?
}
