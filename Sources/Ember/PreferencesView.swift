import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @AppStorage("vaultPath") private var vaultPath: String = ""
    @AppStorage("activeWhisperModel") private var activeModelId: String = "base.en"
    @StateObject private var modelManager = WhisperModelManager.shared
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Obsidian Vault") {
                HStack {
                    TextField("Vault path", text: $vaultPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        selectVaultFolder()
                    }
                }
                if !vaultPath.isEmpty {
                    let exists = FileManager.default.fileExists(atPath: vaultPath)
                    Label(
                        exists ? "Vault found" : "Path does not exist",
                        systemImage: exists ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(exists ? .green : .red)
                    .font(.caption)
                }
            }

            Section("Whisper Model") {
                Picker("Active model", selection: $activeModelId) {
                    ForEach(WhisperModelManager.availableModels) { model in
                        HStack {
                            Text(model.name)
                            if modelManager.isModelDownloaded(model) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .tag(model.id)
                    }
                }

                if let selectedModel = WhisperModelManager.availableModels.first(where: { $0.id == activeModelId }) {
                    if !modelManager.isModelDownloaded(selectedModel) {
                        Button("Download \(selectedModel.name) (\(selectedModel.sizeDescription))") {
                            Task {
                                try? await modelManager.downloadModel(selectedModel)
                            }
                        }
                    }
                }

                if modelManager.isDownloading {
                    ProgressView(value: modelManager.downloadProgress) {
                        Text("Downloading... \(Int(modelManager.downloadProgress * 100))%")
                            .font(.caption)
                    }
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                HStack {
                    Text("Global hotkey")
                    Spacer()
                    Text("Cmd + Shift + R")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 340)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func selectVaultFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your Obsidian vault folder"
        if panel.runModal() == .OK, let url = panel.url {
            vaultPath = url.path
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
