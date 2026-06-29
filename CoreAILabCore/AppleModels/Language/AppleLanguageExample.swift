import Foundation

enum AppleLanguageExample: String, Hashable, Sendable {
    case qwen3_0_6B
    case qwen3_4B
    case gemma3_4BIt
    case gemma3_12BIt

    init?(shortName: String) {
        switch shortName {
        case "qwen3-0.6b":
            self = .qwen3_0_6B
        case "qwen3-4b":
            self = .qwen3_4B
        case "gemma3-4b-it":
            self = .gemma3_4BIt
        case "gemma3-12b-it":
            self = .gemma3_12BIt
        default:
            return nil
        }
    }

    init?(resourceBundleURL: URL) {
        let name = resourceBundleURL.lastPathComponent.lowercased()
        if name.contains("qwen3") && (name.contains("0_6b") || name.contains("0.6b")) {
            self = .qwen3_0_6B
        } else if name.contains("qwen3") && (name.contains("4b") || name.contains("4_b")) {
            self = .qwen3_4B
        } else if name.contains("gemma3") && name.contains("4b") {
            self = .gemma3_4BIt
        } else if name.contains("gemma3") && name.contains("12b") {
            self = .gemma3_12BIt
        } else {
            return nil
        }
    }

    var title: String {
        switch self {
        case .qwen3_0_6B:
            "Qwen3 0.6B"
        case .qwen3_4B:
            "Qwen3 4B"
        case .gemma3_4BIt:
            "Gemma 3 4B IT"
        case .gemma3_12BIt:
            "Gemma 3 12B IT"
        }
    }

    var playgroundButtonTitle: String {
        "Open \(title) Chat"
    }

    var modelIdentifier: String {
        switch self {
        case .qwen3_0_6B:
            "qwen3-0.6b"
        case .qwen3_4B:
            "qwen3-4b"
        case .gemma3_4BIt:
            "gemma3-4b-it"
        case .gemma3_12BIt:
            "gemma3-12b-it"
        }
    }

    var macOSExportCommand: String {
        switch self {
        case .qwen3_0_6B:
            "uv run coreai.llm.export Qwen/Qwen3-0.6B --compression 4bit --compute-precision float16 --max-context-length 8192"
        case .qwen3_4B:
            "uv run coreai.llm.export Qwen/Qwen3-4B --compression 4bit --compute-precision float16 --max-context-length 40960"
        case .gemma3_4BIt:
            "uv run coreai.llm.export google/gemma-3-4b-it --compression 4bit --compute-precision bfloat16 --max-context-length 131072"
        case .gemma3_12BIt:
            "uv run coreai.llm.export google/gemma-3-12b-it --compression 4bit --compute-precision bfloat16 --max-context-length 131072"
        }
    }

    var iOSExportCommand: String? {
        switch self {
        case .qwen3_0_6B:
            "uv run coreai.llm.export Qwen/Qwen3-0.6B --compression-config models/qwen3/qwen3_0_6b_mixed_4bit_8bit.yaml --compute-precision float16 --max-context-length 4096 --platform iOS"
        case .qwen3_4B:
            "uv run coreai.llm.export Qwen/Qwen3-4B --compression-config models/qwen3/qwen3_4b_mixed_4bit_8bit.yaml --compute-precision float16 --max-context-length 4096 --platform iOS"
        case .gemma3_4BIt, .gemma3_12BIt:
            nil
        }
    }
}
