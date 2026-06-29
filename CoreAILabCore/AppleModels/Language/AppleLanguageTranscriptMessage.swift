import Foundation

struct AppleLanguageTranscriptMessage: Identifiable, Equatable, Sendable {
    enum Role: String, Sendable {
        case user
        case assistant
    }

    enum State: Equatable, Sendable {
        case complete
        case pending
        case canceled
        case failed(String)
    }

    let id: UUID
    let role: Role
    var content: String
    var state: State
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        state: State = .complete,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.state = state
        self.createdAt = createdAt
    }

    var isFromUser: Bool {
        role == .user
    }
}
