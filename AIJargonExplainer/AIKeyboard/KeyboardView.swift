import SwiftUI

struct KeyboardView: View {
    let onNextKeyboard: () -> Void
    let hasFullAccess: Bool
    let getClipboard: () -> String?

    @State private var explainedTerms: [ExplainedTerm] = []
    @State private var isLoading = false
    @State private var copiedFeedback = false
    @State private var hasContent = false
    @State private var errorMessage: String? = nil
    @StateObject private var savedTerms = SavedTermsStore()

    private let geminiService = GeminiService()

    private let placeholderText = "Copy AI text from any app, then tap Explain"

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.08, blue: 0.14)
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
                    if let errorMessage = errorMessage {
                        // Error state
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                    } else if hasContent && !explainedTerms.isEmpty {
                        // Term cards
                        VStack(spacing: 6) {
                            ForEach(explainedTerms) { term in
                                KeyboardTermCard(term: term, isSaved: savedTerms.isSaved(term)) {
                                    if savedTerms.isSaved(term) {
                                        savedTerms.remove(term)
                                    } else {
                                        savedTerms.save(term)
                                    }
                                }
                            }
                        }
                        .padding(6)
                    } else {
                        // Placeholder
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
                    .disabled(!hasContent || explainedTerms.isEmpty)
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
                    if !savedTerms.terms.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(savedTerms.terms.count) saved")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow.opacity(0.7))
                        }
                    }
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
            errorMessage = "Full Access is required.\nGo to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access"
            hasContent = true
            return
        }

        guard !SharedDefaults.apiKey.isEmpty,
              SharedDefaults.apiKey != "PASTE_YOUR_GEMINI_API_KEY_HERE" else {
            errorMessage = "No API key found.\nOpen the AI Jargon Explainer app and set your Gemini API key in Constants.swift."
            hasContent = true
            return
        }

        guard let clipText = getClipboard(), !clipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Nothing on clipboard.\nCopy some AI text first (long-press > Copy in any app), then tap Explain."
            hasContent = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let terms = try await geminiService.explainAITerms(text: clipText)
                withAnimation(.easeOut(duration: 0.3)) {
                    explainedTerms = terms
                    hasContent = true
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)\nCheck your internet connection and try again."
                hasContent = true
            }
            isLoading = false
        }
    }

    private func clearContent() {
        explainedTerms = []
        errorMessage = nil
        hasContent = false
    }

    private func copyResult() {
        guard hasContent, !explainedTerms.isEmpty else { return }
        let text = explainedTerms.map { "\($0.term): \($0.explanation)" }.joined(separator: "\n\n")
        UIPasteboard.general.string = text
        copiedFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }
}

// MARK: - Keyboard Term Card (compact for keyboard height)

struct KeyboardTermCard: View {
    let term: ExplainedTerm
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(term.term)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
                Text(term.explanation)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(1)
                    .lineLimit(3)
            }
            Spacer(minLength: 4)
            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 12))
                    .foregroundColor(isSaved ? .yellow : .white.opacity(0.3))
            }
            .frame(width: 24)
        }
        .padding(8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.12), lineWidth: 1))
    }
}
