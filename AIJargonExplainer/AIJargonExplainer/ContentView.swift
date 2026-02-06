import SwiftUI

struct ContentView: View {
    @AppStorage(AppConstants.apiKeyStorageKey, store: UserDefaults(suiteName: AppConstants.appGroupID))
    var apiKey: String = ""

    @State private var showKey = false
    @State private var testText = "This new RAG pipeline uses fine-tuned LLMs with RLHF to improve zero-shot performance on NLP benchmarks."
    @State private var testResult = ""
    @State private var isTesting = false

    private let geminiService = GeminiService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // --- API Key Section ---
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Gemini API Key", systemImage: "key.fill")
                                .font(.headline)

                            HStack {
                                if showKey {
                                    TextField("Paste your API key here", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Paste your API key here", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Button(action: { showKey.toggle() }) {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Get your free key at ai.google.dev")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if !apiKey.isEmpty {
                                Label("Key saved", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    // --- How to Enable Section ---
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("How to Enable the Keyboard", systemImage: "keyboard")
                                .font(.headline)
                                .padding(.bottom, 4)

                            StepRow(number: 1, text: "Open Settings > General > Keyboard > Keyboards")
                            StepRow(number: 2, text: "Tap \"Add New Keyboard...\"")
                            StepRow(number: 3, text: "Select \"AIKeyboard\"")
                            StepRow(number: 4, text: "Tap \"AIKeyboard\" again, enable \"Allow Full Access\"")
                            StepRow(number: 5, text: "In any app, use the globe key to switch keyboards")
                        }
                    }

                    // --- How to Use Section ---
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("How to Use", systemImage: "sparkles")
                                .font(.headline)
                                .padding(.bottom, 4)

                            StepRow(number: 1, text: "Copy AI text from any app (Twitter, LinkedIn, etc.)")
                            StepRow(number: 2, text: "Switch to the AI Explainer keyboard using the globe key")
                            StepRow(number: 3, text: "Tap \"Explain\" to get plain-English explanations")
                            StepRow(number: 4, text: "Tap \"Copy\" to copy the explanation to your clipboard")
                        }
                    }

                    // --- Test Section ---
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Try It Here", systemImage: "play.circle")
                                .font(.headline)

                            TextEditor(text: $testText)
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )

                            Button(action: runTest) {
                                HStack {
                                    if isTesting {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isTesting ? "Explaining..." : "Test Explain")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(apiKey.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(apiKey.isEmpty || isTesting)

                            if !testResult.isEmpty {
                                Text(testResult)
                                    .font(.callout)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Jargon Explainer")
        }
    }

    private func runTest() {
        guard !apiKey.isEmpty, !testText.isEmpty else { return }
        isTesting = true
        testResult = ""

        Task {
            do {
                let result = try await geminiService.explainAITerms(text: testText)
                testResult = result
            } catch {
                testResult = "Error: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .trailing)
            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    ContentView()
}
