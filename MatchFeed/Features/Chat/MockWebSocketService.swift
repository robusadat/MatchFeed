import Foundation
import Combine

// MARK: - Protocol

protocol WebSocketServiceProtocol {
    /// Publisher that emits every incoming message.
    var incomingMessages: AnyPublisher<Message, Never> { get }
    func connect(to conversationId: String)
    func disconnect()
    func send(_ message: Message) async
}

// MARK: - Mock Implementation
// Uses Combine PassthroughSubject + Timer to simulate a live WebSocket.
// Swap this for a real URLSessionWebSocketTask implementation in production.

final class MockWebSocketService: WebSocketServiceProtocol {

    // MARK: - Publisher

    private let subject = PassthroughSubject<Message, Never>()
    var incomingMessages: AnyPublisher<Message, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Private

    private var timerCancellable: AnyCancellable?
    private var partnerId: String = ""

    private let fakeReplies = [
        "Hey! How's your day going? 😊",
        "That's really interesting, tell me more!",
        "I love that spot too — great taste 👌",
        "Haha yeah, same here honestly",
        "What are you up to this weekend?",
        "We should grab coffee sometime ☕️",
        "That's hilarious 😂",
        "You seem really cool tbh",
    ]

    // MARK: - WebSocketServiceProtocol

    func connect(to conversationId: String) {
        partnerId = conversationId
        scheduleNextReply()
    }

    func disconnect() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Simulates a server ack after a short delay.
    func send(_ message: Message) async {
        try? await Task.sleep(for: .milliseconds(Int.random(in: 200...600)))
        // In real code: parse ack from server → update message.status to .sent
    }

    // MARK: - Private

    private func scheduleNextReply() {
        let delay = Double.random(in: 3.0...9.0)
        timerCancellable = Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let text = self.fakeReplies.randomElement() ?? "..."
                let reply = Message(
                    id:        UUID(),
                    senderId:  self.partnerId,
                    body:      text,
                    timestamp: Date(),
                    status:    .sent
                )
                self.subject.send(reply)
                self.scheduleNextReply()  // chain next reply
            }
    }
}
