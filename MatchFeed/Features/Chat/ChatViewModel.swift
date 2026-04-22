import Foundation
import Observation
import Combine

// MARK: - ChatViewModel

@Observable
final class ChatViewModel {

    // MARK: - State
    var messages:       [Message] = []
    var draftText:      String    = ""
    var partnerProfile: UserProfile

    // MARK: - Private
    private let webSocket: any WebSocketServiceProtocol
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        partner: UserProfile,
        webSocket: any WebSocketServiceProtocol = MockWebSocketService()
    ) {
        self.partnerProfile = partner
        self.webSocket      = webSocket
        subscribeToIncoming()
        webSocket.connect(to: partner.id)
    }

    deinit {
        webSocket.disconnect()
    }

    // MARK: - Intents

    func send() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let message = Message.outgoing(text)
        draftText = ""

        // 1. Optimistic insert — UI updates immediately
        messages.append(message)

        // 2. Fire to "server" (mock or real WebSocket)
        Task {
            await webSocket.send(message)
            // TODO: find message by id, flip status to .sent (or .failed on throw)
        }
    }

    // MARK: - Private

    private func subscribeToIncoming() {
        webSocket.incomingMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.messages.append(message)
            }
            .store(in: &bag)
    }
}
