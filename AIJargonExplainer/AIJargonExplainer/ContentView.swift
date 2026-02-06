import SwiftUI

struct ContentView: View {
    @State private var testText = "This new RAG pipeline uses fine-tuned LLMs with RLHF to improve zero-shot performance on NLP benchmarks."
    @State private var testResult = ""
    @State private var isTesting = false
    @State private var selectedTab = 0
    @State private var showOnboarding = true

    private let geminiService = GeminiService()

    private var hasAPIKey: Bool {
        AppConstants.geminiAPIKey != "PASTE_YOUR_GEMINI_API_KEY_HERE" && !AppConstants.geminiAPIKey.isEmpty
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.08, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // --- Hero Section ---
                    heroSection
                        .padding(.top, 20)

                    // --- API Status Pill ---
                    apiStatusPill
                        .padding(.top, 16)

                    // --- Try It Section ---
                    tryItSection
                        .padding(.top, 28)

                    // --- How It Works ---
                    howItWorksSection
                        .padding(.top, 32)

                    // --- Setup Steps ---
                    setupSection
                        .padding(.top, 32)

                    // --- Footer ---
                    footerSection
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("AI Jargon")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                +
                Text(" Explainer")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.purple.opacity(0.9))

                Text("Decode AI buzzwords in seconds")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - API Status Pill

    private var apiStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasAPIKey ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(hasAPIKey ? "Gemini API Connected" : "API Key Required")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
    }

    // MARK: - Try It Section

    private var tryItSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                Text("Try It Now")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Input area
            VStack(alignment: .leading, spacing: 8) {
                Text("PASTE AI TEXT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                TextEditor(text: $testText)
                    .font(.system(size: 14))
                    .frame(height: 80)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            // Explain button
            Button(action: runTest) {
                HStack(spacing: 8) {
                    if isTesting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                    }
                    Text(isTesting ? "Analyzing..." : "Explain This")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: hasAPIKey ? [Color.purple, Color.blue] : [Color.gray, Color.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.purple.opacity(hasAPIKey ? 0.4 : 0), radius: 12, y: 4)
            }
            .disabled(!hasAPIKey || isTesting)

            // Result area
            if !testResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("EXPLANATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = testResult
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("Copy")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.purple)
                        }
                    }

                    Text(testResult)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How It Works")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                FeatureCard(
                    icon: "doc.on.clipboard",
                    iconColor: .blue,
                    title: "Copy",
                    description: "Copy any AI text from Twitter, LinkedIn, or any app"
                )
                FeatureCard(
                    icon: "globe",
                    iconColor: .purple,
                    title: "Switch",
                    description: "Tap the globe key to switch to AI Explainer keyboard"
                )
                FeatureCard(
                    icon: "sparkles",
                    iconColor: .orange,
                    title: "Explain",
                    description: "Tap Explain and get instant plain-English definitions"
                )
                FeatureCard(
                    icon: "doc.on.doc",
                    iconColor: .green,
                    title: "Copy & Share",
                    description: "Copy the explanation and share it anywhere"
                )
            }
        }
    }

    // MARK: - Setup Section

    private var setupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Setup")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                SetupStep(number: 1, text: "Settings > General > Keyboard > Keyboards", isLast: false)
                SetupStep(number: 2, text: "Add New Keyboard > AIKeyboard", isLast: false)
                SetupStep(number: 3, text: "Tap AIKeyboard > Allow Full Access", isLast: false)
                SetupStep(number: 4, text: "Use globe key to switch keyboards", isLast: true)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Powered by Google Gemini")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
            Text("Free tier: 15 requests/min")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
        }
    }

    // MARK: - Actions

    private func runTest() {
        guard hasAPIKey, !testText.isEmpty else { return }
        isTesting = true
        testResult = ""

        Task {
            do {
                let result = try await geminiService.explainAITerms(text: testText)
                withAnimation(.easeOut(duration: 0.3)) {
                    testResult = result
                }
            } catch {
                withAnimation {
                    testResult = "Error: \(error.localizedDescription)"
                }
            }
            isTesting = false
        }
    }
}

// MARK: - Feature Card Component

struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

// MARK: - Setup Step Component

struct SetupStep: View {
    let number: Int
    let text: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("\(number)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.purple)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 2, height: 24)
                }
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
