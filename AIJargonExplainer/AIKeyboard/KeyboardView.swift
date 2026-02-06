import SwiftUI

struct KeyboardView: View {
    let onNextKeyboard: () -> Void
    let hasFullAccess: Bool
    let getClipboard: () -> String?

    @State private var explanationText = "Copy AI text from any app, then tap \"Explain\" to understand it."
    @State private var isLoading = false
    @State private var copiedFeedback = false

    private let geminiService = GeminiService()

    var body: some View {
        VStack(spacing: 6) {

            // --- Explanation Display Area ---
            ScrollView {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Thinking...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                } else {
                    Text(explanationText)
                        .font(.system(size: 13.5))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
            }
            .frame(height: 160)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 8)
            .padding(.top, 4)

            // --- Action Buttons Row ---
            HStack(spacing: 6) {
                // Explain button
                Button(action: explainClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Explain")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isLoading ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)

                // Clear button
                Button(action: {
                    explanationText = "Copy AI text from any app, then tap \"Explain\" to understand it."
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12))
                        Text("Clear")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray4))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }

                // Copy button
                Button(action: copyResult) {
                    HStack(spacing: 4) {
                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copiedFeedback ? "Copied!" : "Copy")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(copiedFeedback ? Color.green.opacity(0.3) : Color(.systemGray4))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)

            // --- Bottom Row: Globe Key ---
            HStack {
                Button(action: onNextKeyboard) {
                    Image(systemName: "globe")
                        .font(.system(size: 20))
                        .padding(8)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("AI Explainer")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                // Spacer to balance the globe button
                Color.clear
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)
        }
    }

    // MARK: - Actions

    private func explainClipboard() {
        // Check Full Access
        guard hasFullAccess else {
            explanationText = "Full Access is required.\n\nGo to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access"
            return
        }

        // Check API key
        guard !SharedDefaults.apiKey.isEmpty else {
            explanationText = "No API key found.\n\nOpen the AI Jargon Explainer app and enter your Gemini API key."
            return
        }

        // Check clipboard
        guard let clipText = getClipboard(), !clipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            explanationText = "Nothing on clipboard.\n\nCopy some AI text first (long-press > Copy in any app), then tap Explain."
            return
        }

        // Call Gemini
        isLoading = true

        Task {
            do {
                let result = try await geminiService.explainAITerms(text: clipText)
                explanationText = result
            } catch {
                explanationText = "Error: \(error.localizedDescription)\n\nCheck your internet connection and try again."
            }
            isLoading = false
        }
    }

    private func copyResult() {
        UIPasteboard.general.string = explanationText
        copiedFeedback = true

        // Reset the "Copied!" feedback after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }
}
