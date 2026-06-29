import SwiftUI

struct AppleLanguageChatMessageRow: View {
    let message: AppleLanguageTranscriptMessage

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
            Label(senderName, systemImage: senderImageName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                switch message.state {
                case .pending:
                    ProgressView("Generating")
                        .controlSize(.small)
                        .accessibilityAddTraits(.updatesFrequently)
                case .canceled:
                    Label("Generation canceled", systemImage: "stop.fill")
                        .foregroundStyle(.secondary)
                case .failed(let failure):
                    Label(failure, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                case .complete:
                    Text(message.content)
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal, message.isFromUser ? 14 : 0)
            .padding(.vertical, message.isFromUser ? 10 : 0)
            .background(message.isFromUser ? Color.accentColor.opacity(0.16) : .clear, in: .rect(cornerRadius: 12))
        }
        .frame(maxWidth: message.isFromUser ? 560 : 720, alignment: message.isFromUser ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
        .contextMenu {
            if !message.content.isEmpty {
                Button("Copy Message", systemImage: "doc.on.doc", action: copyMessage)
                ShareLink(item: message.content) {
                    Label("Share Message", systemImage: "square.and.arrow.up")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(senderName)
        .accessibilityValue(accessibilityValue)
    }

    private var senderName: String {
        message.isFromUser ? "You" : "Core AI"
    }

    private var senderImageName: String {
        message.isFromUser ? "person.crop.circle" : "cpu"
    }

    private var accessibilityValue: String {
        switch message.state {
        case .pending:
            "Generating response"
        case .canceled:
            "Generation canceled"
        case .failed(let failure):
            failure
        case .complete:
            message.content
        }
    }

    private func copyMessage() {
#if os(iOS)
        UIPasteboard.general.string = message.content
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
#endif
    }
}
