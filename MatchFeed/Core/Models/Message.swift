import Foundation

// MARK: - Message

struct Message: Identifiable, Hashable {
    let id: UUID
    let senderId: String    // "me" or partner's UserProfile.id
    let body: String
    let timestamp: Date
    var status: Status

    enum Status: Hashable {
        case pending    // optimistically inserted, awaiting server ack
        case sent       // server acknowledged
        case failed     // delivery failed
    }
}

// MARK: - Convenience

extension Message {
    /// Creates an outgoing message in the pending state.
    static func outgoing(_ text: String) -> Message {
        Message(
            id: UUID(),
            senderId: "me",
            body: text,
            timestamp: Date(),
            status: .pending
        )
    }

    var isOutgoing: Bool { senderId == "me" }
}
