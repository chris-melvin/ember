import Foundation

struct WhisperModel: Identifiable {
    let id: String
    let name: String
    let filename: String
    let url: URL
    let sizeDescription: String
}

class WhisperModelManager: ObservableObject {
    static let shared = WhisperModelManager()

    static let availableModels: [WhisperModel] = [
        WhisperModel(
            id: "base.en",
            name: "Base (English)",
            filename: "ggml-base.en.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin")!,
            sizeDescription: "~148 MB"
        ),
        WhisperModel(
            id: "base",
            name: "Base (Multilingual)",
            filename: "ggml-base.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin")!,
            sizeDescription: "~148 MB"
        ),
        WhisperModel(
            id: "medium.en",
            name: "Medium (English)",
            filename: "ggml-medium.en.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin")!,
            sizeDescription: "~1.5 GB"
        ),
        WhisperModel(
            id: "large-v3-turbo",
            name: "Large v3 Turbo",
            filename: "ggml-large-v3-turbo.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin")!,
            sizeDescription: "~1.6 GB"
        ),
    ]

    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var downloadError: String?

    private var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Ember/Models", isDirectory: true)
    }

    var activeModelId: String {
        get { UserDefaults.standard.string(forKey: "activeWhisperModel") ?? "base.en" }
        set { UserDefaults.standard.set(newValue, forKey: "activeWhisperModel") }
    }

    func modelPath(for model: WhisperModel) -> URL {
        modelsDirectory.appendingPathComponent(model.filename)
    }

    func activeModelPath() -> URL? {
        guard let model = Self.availableModels.first(where: { $0.id == activeModelId }) else { return nil }
        let path = modelPath(for: model)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    func isModelDownloaded(_ model: WhisperModel) -> Bool {
        FileManager.default.fileExists(atPath: modelPath(for: model).path)
    }

    func hasAnyModel() -> Bool {
        Self.availableModels.contains { isModelDownloaded($0) }
    }

    func downloadModel(_ model: WhisperModel) async throws {
        try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        await MainActor.run {
            isDownloading = true
            downloadProgress = 0
            downloadError = nil
        }

        let destination = modelPath(for: model)

        let delegate = DownloadDelegate { progress in
            Task { @MainActor in
                self.downloadProgress = progress
            }
        }

        let (tempURL, _) = try await URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            .download(from: model.url)

        try FileManager.default.moveItem(at: tempURL, to: destination)

        await MainActor.run {
            isDownloading = false
            activeModelId = model.id
        }
    }

    func ensureDefaultModel() async throws {
        guard !hasAnyModel() else { return }
        let defaultModel = Self.availableModels.first { $0.id == "base.en" }!
        try await downloadModel(defaultModel)
    }
}

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void

    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled by the async download call
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }
}
