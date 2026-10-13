import Foundation
@testable import MasterMailCore
import Testing

struct ConversationTests {
    private func msg(_ id: String, index: Data, minutesAgo: Int) -> StoredMessage {
        let json = """
        {"id":"\(id)","subject":"s","conversationId":"c","conversationIndex":"\(index.base64EncodedString())",
         "receivedDateTime":"\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(-minutesAgo) * 60)))",
         "isRead":true,"hasAttachments":false}
        """
        return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
    }

    @Test func buildsDepthAndBranches() {
        let root = Data(repeating: 1, count: 22)
        let reply1 = root + Data([0, 0, 0, 0, 1])      // responde à raiz
        let reply2 = root + Data([0, 0, 0, 0, 2])      // responde à raiz também → Ramo
        let reply1a = reply1 + Data([0, 0, 0, 0, 3])   // responde à reply1
        let nodes = ConversationTree.build([
            msg("r1a", index: reply1a, minutesAgo: 10),
            msg("root", index: root, minutesAgo: 60),
            msg("r2", index: reply2, minutesAgo: 20),
            msg("r1", index: reply1, minutesAgo: 40),
        ])
        #expect(nodes.map(\.id) == ["root", "r1", "r2", "r1a"]) // cronológico
        #expect(nodes.map(\.depth) == [0, 1, 1, 2])
        #expect(nodes.map(\.parentID) == [nil, "root", "root", "r1"])
        #expect(nodes.map(\.isBranch) == [false, true, true, false])
    }

    @Test func missingParentLinksToNearestAncestor() {
        let root = Data(repeating: 1, count: 22)
        let grandchild = root + Data([0, 0, 0, 0, 1]) + Data([0, 0, 0, 0, 2])
        let nodes = ConversationTree.build([msg("root", index: root, minutesAgo: 5), msg("gc", index: grandchild, minutesAgo: 1)])
        #expect(nodes.last?.parentID == "root")
        #expect(nodes.last?.depth == 1)
    }

    @Test func oldMessagesKeepTextButDropHTML() throws {
        let json = """
        {"id":"old","receivedDateTime":"2020-01-01T00:00:00Z","isRead":true,"hasAttachments":false,
         "body":{"contentType":"html","content":"<p>antigo</p>"}}
        """
        let m = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
        #expect(m.bodyHTML == nil)
        #expect(m.bodyText == "antigo")
    }
}
