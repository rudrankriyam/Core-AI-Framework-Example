import SwiftUI

struct AppleLanguagePromptComposerView: View {
    @Bindable var workspace: AppleLanguageWorkspaceModel

    var body: some View {
        Section {
            TextField("Ask the local language model", text: $workspace.prompt, axis: .vertical)
                .lineLimit(2...8)
                .disabled(!workspace.canEditGenerationInputs)
#if os(iOS)
                .submitLabel(.send)
#endif

            Stepper(
                "Maximum response tokens: \(workspace.maximumResponseTokens)",
                value: $workspace.maximumResponseTokens,
                in: 1...512,
                step: 16
            )
            .disabled(!workspace.canEditGenerationInputs)

            ViewThatFits(in: .horizontal) {
                generationActions(axis: .horizontal)
                generationActions(axis: .vertical)
            }
        } header: {
            Label("Prompt", systemImage: "arrow.up.message")
        }
    }

    private func generationActions(axis: Axis) -> some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout())
            : AnyLayout(VStackLayout(alignment: .leading))

        return layout {
            if workspace.isGenerating {
                Button(
                    "Cancel",
                    systemImage: "stop.fill",
                    role: .cancel,
                    action: workspace.cancelGeneration
                )
            } else {
                Button("Send", systemImage: "arrow.up", action: workspace.startGeneration)
                    .buttonStyle(.borderedProminent)
                    .disabled(!workspace.canGenerate)
            }
        }
    }
}
