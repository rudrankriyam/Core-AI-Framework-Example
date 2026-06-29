import Foundation
import Observation

@MainActor
@Observable
final class AppleLanguageWorkspaceModel {
    let example: AppleLanguageExample
    let runCoordinator: CoreAIRunLifecycleCoordinator
    private(set) var modelName: String?
    private(set) var response = ""
    private(set) var transcript: [AppleLanguageTranscriptMessage] = []
    private(set) var statusMessage = "Import an Apple-exported language-model resource bundle."
    private(set) var isLoadingModel = false
    private(set) var isGenerating = false
    private(set) var isResettingSession = false
    private(set) var errorMessage: String?
    var prompt = "Explain why on-device AI is useful in three sentences."
    var maximumResponseTokens = 128
    var isShowingError = false

    @ObservationIgnored
    private let engine: any AppleLanguageGenerating
    @ObservationIgnored
    private var generationTask: Task<Void, Never>?
    @ObservationIgnored
    let runContext: CoreAIRuntimeRunContext

    init(
        example: AppleLanguageExample,
        engine: any AppleLanguageGenerating = AppleLanguageModelEngine(),
        runContext: CoreAIRuntimeRunContext? = nil,
        runCoordinator: CoreAIRunLifecycleCoordinator? = nil
    ) {
        self.example = example
        self.engine = engine
        self.runContext = runContext ?? .workspaceDefault(
            experienceID: "apple-language-\(example.rawValue)",
            title: example.title,
            modelIdentifier: example.modelIdentifier
        )
        self.runCoordinator = runCoordinator ?? CoreAIRunLifecycleCoordinator()
    }

    var isBusy: Bool {
        isLoadingModel || isGenerating || isResettingSession
    }

    var canGenerate: Bool {
        modelName != nil && !normalizedPrompt.isEmpty && !isBusy
    }

    var canEditGenerationInputs: Bool {
        !isBusy
    }

    func loadModel(from url: URL) async {
        guard !isBusy else { return }
        isLoadingModel = true
        statusMessage = "Loading \(url.lastPathComponent) and its tokenizer…"
        defer { isLoadingModel = false }

        do {
            try CoreAIRuntimeArtifactValidator.validate(
                url,
                for: .appleLanguage,
                context: runContext
            )
            try await engine.loadModel(at: url)
            modelName = url.lastPathComponent
            runCoordinator.modelDidLoad(
                context: runContext,
                modelIdentity: url.lastPathComponent
            )
            response = ""
            transcript = []
            clearError()
            statusMessage = "\(example.title) is ready for a chat session."
        } catch {
            present(error)
        }
    }

    func startGeneration() {
        guard generationTask == nil, canGenerate else { return }
        let submittedPrompt = normalizedPrompt
        let submittedMaximumTokens = maximumResponseTokens
        let assistantMessageID = UUID()
        transcript.append(
            AppleLanguageTranscriptMessage(
                role: .user,
                content: submittedPrompt
            )
        )
        transcript.append(
            AppleLanguageTranscriptMessage(
                id: assistantMessageID,
                role: .assistant,
                content: "",
                state: .pending
            )
        )
        prompt = ""
        response = ""
        isGenerating = true
        statusMessage = "Generating locally with \(example.title)…"
        let runToken = runCoordinator.start(
            context: runContext,
            modelIdentity: modelName ?? runContext.comparisonIdentity.modelIdentifier
        )
        let coordinator = runCoordinator
        generationTask = Task { [weak self, coordinator] in
            guard let self else {
                coordinator.cancel(runToken, summary: "Language workspace closed.")
                return
            }
            await self.performGeneration(
                prompt: submittedPrompt,
                maximumResponseTokens: submittedMaximumTokens,
                runToken: runToken,
                assistantMessageID: assistantMessageID
            )
        }
    }

    func cancelGeneration() {
        guard generationTask != nil else { return }
        statusMessage = "Canceling generation…"
        generationTask?.cancel()
    }

    func resetSession() async {
        guard modelName != nil, !isBusy else { return }
        isResettingSession = true
        defer { isResettingSession = false }

        do {
            try await engine.resetSession()
            response = ""
            transcript = []
            clearError()
            statusMessage = "Started a fresh \(example.title) session."
        } catch {
            present(error)
        }
    }

    func presentImportError(_ error: any Error) {
        present(error)
    }

    private var normalizedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func performGeneration(
        prompt: String,
        maximumResponseTokens: Int,
        runToken: CoreAIRuntimeRunToken,
        assistantMessageID: UUID
    ) async {
        defer {
            generationTask = nil
            isGenerating = false
        }

        do {
            let generated = try await engine.respond(
                to: prompt,
                maximumResponseTokens: maximumResponseTokens
            )
            try Task.checkCancellation()
            response = generated
            updateAssistantMessage(
                id: assistantMessageID,
                content: generated,
                state: .complete
            )
            clearError()
            statusMessage = "Generated \(generated.count) characters on device."
            runCoordinator.succeed(runToken, summary: statusMessage)
        } catch is CancellationError {
            response = ""
            statusMessage = "Generation canceled."
            updateAssistantMessage(
                id: assistantMessageID,
                content: "",
                state: .canceled
            )
            runCoordinator.cancel(runToken, summary: statusMessage)
        } catch {
            runCoordinator.fail(runToken, error: error)
            updateAssistantMessage(
                id: assistantMessageID,
                content: "",
                state: .failed(error.localizedDescription)
            )
            present(error)
        }
    }

    private func updateAssistantMessage(
        id: UUID,
        content: String,
        state: AppleLanguageTranscriptMessage.State
    ) {
        guard let index = transcript.firstIndex(where: { $0.id == id }) else { return }
        transcript[index].content = content
        transcript[index].state = state
    }

    private func present(_ error: any Error) {
        errorMessage = error.localizedDescription
        statusMessage = error.localizedDescription
        isShowingError = true
    }

    private func clearError() {
        errorMessage = nil
        isShowingError = false
    }
}
