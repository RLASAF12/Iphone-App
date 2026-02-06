import SwiftUI

struct KeyboardView: View {
    let onNextKeyboard: () -> Void
    let hasFullAccess: Bool
    let getClipboard: () -> String?

    @State private var explanationText = ""
    @State private var isLoading = false
    @State private var copiedFeedback = false
    @State private var hasContent = false

    private let geminiService = GeminiService()

    private let placeholderText = "Copy AI text from any app, then tap Explain"

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.12, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // --- Top Bar ---
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                        Text("AI Explainer")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    if isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.purple)
                            Text("Analyzing...")
                                .font(.system(size: 11))
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 4)

                // --- Explanation Display Area ---
                ScrollView {
                    if hasContent {
                        Text(explanationText)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.3))
                            Text(placeholderText)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                    }
                }
                .frame(height: 150)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            hasContent ? Color.green.opacity(0.2) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 8)

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
                        .background(
                            LinearGradient(
                                colors: isLoading ? [Color.purple.opacity(0.3)] : [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)

                    // Clear button
                    Button(action: clearContent) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 44)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.6))
                            .cornerRadius(8)
                    }

                    // Copy button
                    Button(action: copyResult) {
                        HStack(spacing: 4) {
                            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            Text(copiedFeedback ? "Copied!" : "Copy")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(copiedFeedback ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
                        .foregroundColor(copiedFeedback ? .green : .white.opacity(0.7))
                        .cornerRadius(8)
                    }
                    .disabled(!hasContent)
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)

                // --- Bottom Row: Globe Key ---
                HStack {
                    Button(action: onNextKeyboard) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .padding(8)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)
                .padding(.bottom, 2)
            }
        }
    }

    // MARK: - Actions

    private func explainClipboard() {
        guard hasFullAccess else {
            explanationText = "Full Access is required.\n\nGo to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access"
            hasContent = true
            return
        }

        guard !SharedDefaults.apiKey.isEmpty,
              SharedDefaults.apiKey != "PASTE_YOUR_GEMINI_API_KEY_HERE" else {
            explanationText = "No API key found.\n\nOpen the AI Jargon Explainer app and set your Gemini API key in Constants.swift."
            hasContent = true
            return
        }

        guard let clipText = getClipboard(), !clipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            explanationText = "Nothing on clipboard.\n\nCopy some AI text first (long-press > Copy in any app), then tap Explain."
            hasContent = true
            return
        }

        isLoading = true

        Task {
            do {
                let result = try await geminiService.explainAITerms(text: clipText)
                explanationText = result
                hasContent = true
            } catch {
                explanationText = "Error: \(error.localizedDescription)\n\nCheck your internet connection and try again."
                hasContent = true
            }
            isLoading = false
        }
    }

    private func clearContent() {
        explanationText = ""
        hasContent = false
    }

    private func copyResult() {
        guard hasContent else { return }
        UIPasteboard.general.string = explanationText
        copiedFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }
}
