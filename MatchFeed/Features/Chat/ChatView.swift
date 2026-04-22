import SwiftUI

// MARK: - ChatView

struct ChatView: View {

    @State private var viewModel: ChatViewModel

    init(partner: UserProfile) {
        _viewModel = State(initialValue: ChatViewModel(partner: partner))
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .navigationTitle(viewModel.partnerProfile.firstName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $viewModel.draftText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .submitLabel(.send)
                .onSubmit { viewModel.send() }

            Button(action: viewModel.send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.draftText.isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.draftText.isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(12)
        .background(.background)
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {

    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 3) {
                Text(message.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isOutgoing ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(message.isOutgoing ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if message.isOutgoing {
                    statusIndicator
                }
            }

            if !message.isOutgoing { Spacer(minLength: 60) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Status icon (pending / sent / failed)

    @ViewBuilder
    private var statusIndicator: some View {
        switch message.status {
        case .pending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }

    private var accessibilityDescription: String {
        let sender = message.isOutgoing ? "You" : "Them"
        return "\(sender): \(message.body)"
    }
}
