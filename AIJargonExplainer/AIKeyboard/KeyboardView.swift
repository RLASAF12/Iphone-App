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
    @State private var showSavedTerms = false
    @StateObject private var savedTerms = SavedTermsStore()

    private let geminiService = GeminiService()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.12),
                    Color(red: 0.10, green: 0.08, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // --- Top Bar ---
                HStack {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 20, height: 20)
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("AI Explainer")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    if isLoading {
                        HStack(spacing: 5) {
                            ProgressView()
                                .scaleEffect(0.55)
                                .tint(.purple)
                            Text("Thinking...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 4)

                // --- Results Area (taller — globe row removed) ---
                ScrollView(.vertical, showsIndicators: false) {
                    if showSavedTerms {
                        // Show saved terms list
                        savedTermsOverlay
                    } else if let errorMessage = errorMessage {
                        // Error state
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(Color.orange.opacity(0.15)).frame(width: 28, height: 28)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(2)
                        }
                        .padding(10)

                    } else if hasContent && !explainedTerms.isEmpty {
                        // Term cards
                        VStack(spacing: 5) {
                            ForEach(explainedTerms) { term in
                                KBTermCard(term: term, isSaved: savedTerms.isSaved(term)) {
                                    withAnimation(.spring(response: 0.3)) {
                                        if savedTerms.isSaved(term) {
                                            savedTerms.remove(term)
                                        } else {
                                            savedTerms.save(term)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)

                    } else {
                        // Placeholder
                        VStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.15))
                            Text("Copy AI text, then tap Explain")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    }
                }
                .frame(height: 170)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            showSavedTerms
                                ? Color.yellow.opacity(0.25)
                                : (hasContent && errorMessage == nil
                                    ? Color.purple.opacity(0.2)
                                    : Color.white.opacity(0.06)),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 8)

                // --- Action Buttons Row ---
                HStack(spacing: 5) {
                    // Explain button — hero CTA
                    Button(action: explainClipboard) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                            Text("Explain")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: isLoading
                                    ? [Color.purple.opacity(0.3)]
                                    : [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: isLoading ? .clear : Color.purple.opacity(0.35), radius: 8, y: 3)
                    }
                    .disabled(isLoading)

                    // Clear
                    Button(action: clearContent) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 38)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.07))
                            .foregroundColor(.white.opacity(0.5))
                            .cornerRadius(10)
                    }

                    // Copy
                    Button(action: copyResult) {
                        HStack(spacing: 4) {
                            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                            Text(copiedFeedback ? "Done" : "Copy")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(copiedFeedback ? Color.green.opacity(0.15) : Color.white.opacity(0.07))
                        .foregroundColor(copiedFeedback ? .green : .white.opacity(0.6))
                        .cornerRadius(10)
                    }
                    .disabled(!hasContent || explainedTerms.isEmpty)

                    // Saved terms toggle button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showSavedTerms.toggle()
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: showSavedTerms ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 38)
                                .padding(.vertical, 11)
                                .background(showSavedTerms ? Color.yellow.opacity(0.15) : Color.white.opacity(0.07))
                                .foregroundColor(showSavedTerms ? .yellow : .white.opacity(0.5))
                                .cornerRadius(10)

                            // Badge count
                            if !savedTerms.terms.isEmpty {
                                Text("\(savedTerms.terms.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.yellow.opacity(0.8))
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 4)

                // No globe row — iOS provides the system globe key already
            }
        }
    }

    // MARK: - Saved Terms Overlay (shown inside the results area)

    private var savedTermsOverlay: some View {
        VStack(spacing: 5) {
            if savedTerms.terms.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No saved terms yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                    Text("Tap the bookmark icon on any term to save it")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.15))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
            } else {
                ForEach(savedTerms.terms) { term in
                    KBTermCard(term: term, isSaved: true) {
                        withAnimation(.spring(response: 0.3)) {
                            savedTerms.remove(term)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func explainClipboard() {
        // Switch back to results view if showing saved terms
        if showSavedTerms {
            showSavedTerms = false
        }

        guard hasFullAccess else {
            errorMessage = "Full Access required. Go to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access"
            hasContent = true
            return
        }

        guard !SharedDefaults.apiKey.isEmpty,
              SharedDefaults.apiKey != "PASTE_YOUR_GEMINI_API_KEY_HERE" else {
            errorMessage = "No API key. Open the AI Jargon app to set up your key."
            hasContent = true
            return
        }

        guard let clipText = getClipboard(), !clipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Clipboard empty. Copy some AI text first, then tap Explain."
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
                errorMessage = "Connection error. Check your internet and try again."
                hasContent = true
            }
            isLoading = false
        }
    }

    private func clearContent() {
        withAnimation(.easeOut(duration: 0.2)) {
            explainedTerms = []
            errorMessage = nil
            hasContent = false
            showSavedTerms = false
        }
    }

    private func copyResult() {
        guard hasContent, !explainedTerms.isEmpty else { return }
        let text = explainedTerms.map { "[\($0.term)] \($0.explanation)" }.joined(separator: "\n\n")
        UIPasteboard.general.string = text
        copiedFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }
}

// MARK: - Compact Term Card for Keyboard

struct KBTermCard: View {
    let term: ExplainedTerm
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Term badge
            VStack(alignment: .leading, spacing: 3) {
                Text(term.term)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(6)

                Text(term.explanation)
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(1.5)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            // Bookmark button
            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 13))
                    .foregroundColor(isSaved ? .yellow : .white.opacity(0.25))
            }
            .frame(width: 26, height: 26)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSaved ? Color.yellow.opacity(0.2) : Color.purple.opacity(0.1), lineWidth: 1)
        )
    }
}
