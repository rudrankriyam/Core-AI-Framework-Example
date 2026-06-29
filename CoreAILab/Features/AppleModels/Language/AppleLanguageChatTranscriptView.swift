import SwiftUI

struct AppleLanguageChatTranscriptView: View {
    let messages: [AppleLanguageTranscriptMessage]

    var body: some View {
        Section {
            if messages.isEmpty {
                ContentUnavailableView(
                    "No Messages Yet",
                    systemImage: "text.bubble",
                    description: Text("Import a language bundle, then send a prompt to start the session.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(messages) { message in
                                AppleLanguageChatMessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(minHeight: 260)
                    .onChange(of: messages.last?.id) { _, latestID in
                        guard let latestID else { return }
                        proxy.scrollTo(latestID, anchor: .bottom)
                    }
                }
            }
        } header: {
            Label("Chat", systemImage: "bubble.left.and.bubble.right")
        }
    }
}
