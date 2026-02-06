# AI Jargon Explainer - Xcode Setup Guide

Since Xcode project files (.xcodeproj) can't be generated outside of Xcode,
follow these steps to create the project and add the source files.

## Prerequisites

- A Mac computer (Xcode only runs on macOS)
- Xcode 15 or 16 (free from Mac App Store)
- Apple ID (free account works for device testing)
- Gemini API key (free from https://ai.google.dev)

---

## Step 1: Create the Xcode Project

1. Open Xcode
2. File > New > Project
3. Select **iOS > App**, click Next
4. Fill in:
   - Product Name: `AIJargonExplainer`
   - Team: Your Apple ID
   - Organization Identifier: `com.aijargonexplainer` (or your own)
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Click Create, save to your desired location

## Step 2: Add the Keyboard Extension Target

1. File > New > Target
2. Select **iOS > Custom Keyboard Extension**, click Next
3. Product Name: `AIKeyboard`
4. Click Finish
5. When prompted "Activate AIKeyboard scheme?", click **Activate**

## Step 3: Enable App Groups

For BOTH targets (AIJargonExplainer AND AIKeyboard):

1. Select the project in the navigator (blue icon at top)
2. Select the target (e.g., AIJargonExplainer)
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Search for and add "App Groups"
6. Click the "+" under App Groups and add: `group.com.aijargonexplainer.shared`
7. **Repeat for the AIKeyboard target**

## Step 4: Replace Source Files

### Main App Target (AIJargonExplainer):
- Replace the auto-generated `AIJargonExplainerApp.swift` with the one from `AIJargonExplainer/`
- Replace the auto-generated `ContentView.swift` with the one from `AIJargonExplainer/`

### Keyboard Extension Target (AIKeyboard):
- Replace the auto-generated `KeyboardViewController.swift` with the one from `AIKeyboard/`
- Add `KeyboardView.swift` from `AIKeyboard/`
- Add `GeminiService.swift` from `AIKeyboard/`
- Replace the auto-generated `Info.plist` with the one from `AIKeyboard/`

### Shared Files:
- Add `Shared/Constants.swift` to the project
- Add `Shared/SharedDefaults.swift` to the project
- **IMPORTANT**: For both shared files, select them in the navigator, open the
  File Inspector (right panel), and check BOTH targets under "Target Membership":
  - [x] AIJargonExplainer
  - [x] AIKeyboard

### Entitlements:
- The `.entitlements` files should be auto-generated when you add App Groups.
  Verify they contain `group.com.aijargonexplainer.shared`.

## Step 5: Verify Info.plist

Open `AIKeyboard/Info.plist` and verify it contains:
- `NSExtension > NSExtensionAttributes > RequestsOpenAccess` = YES
- `NSExtension > NSExtensionPointIdentifier` = `com.apple.keyboard-service`

## Step 6: Build & Run

1. Select the **AIJargonExplainer** scheme (not AIKeyboard)
2. Select your iPhone or a simulator
3. Press Cmd+R to build and run
4. The main app opens — enter your Gemini API key
5. Try the "Test Explain" button to verify the API works

## Step 7: Enable the Keyboard on Your Device

1. On the iPhone, go to **Settings > General > Keyboard > Keyboards**
2. Tap **Add New Keyboard...**
3. Select **AIKeyboard** (under your app name)
4. Tap **AIKeyboard** in the list
5. Toggle **Allow Full Access** > confirm the dialog
6. Open any app with a text field (Messages, Notes, etc.)
7. Tap the globe key to switch to AI Explainer keyboard

## Step 8: Test the Full Flow

1. Open Twitter/X or LinkedIn
2. Find a post with AI jargon
3. Long-press on the text > Copy
4. Tap a text field to bring up the keyboard
5. Tap the globe key to switch to AI Explainer
6. Tap "Explain" — you should see explanations appear!
7. Tap "Copy" to copy the explanation

---

## Troubleshooting

### "Full Access is required" message
Go to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access

### "No API key found" message
Open the main AI Jargon Explainer app and enter your Gemini API key

### Keyboard doesn't appear in the list
Make sure you built the AIJargonExplainer scheme (not AIKeyboard) and ran it on the device

### API errors
- Check your internet connection
- Verify your API key at https://ai.google.dev
- Free tier limit is ~15 requests per minute

### Keyboard crashes on real device
The memory limit for keyboard extensions is ~48MB. The app is designed to stay
within this limit, but if you add heavy images or libraries, it may crash.

---

## Project Structure

```
AIJargonExplainer/
├── AIJargonExplainer/              (Main App - onboarding & setup)
│   ├── AIJargonExplainerApp.swift  (App entry point)
│   ├── ContentView.swift           (Setup UI with API key + instructions + test)
│   ├── Info.plist                  (Main app configuration)
│   └── AIJargonExplainer.entitlements
│
├── AIKeyboard/                     (Keyboard Extension - the actual keyboard)
│   ├── KeyboardViewController.swift (UIKit bridge to SwiftUI)
│   ├── KeyboardView.swift          (SwiftUI keyboard UI)
│   ├── GeminiService.swift         (Gemini API network calls)
│   ├── Info.plist                  (Extension config: RequestsOpenAccess=true)
│   └── AIKeyboard.entitlements
│
└── Shared/                         (Shared between both targets)
    ├── Constants.swift             (App Group ID, API endpoint)
    └── SharedDefaults.swift        (UserDefaults wrapper for shared data)
```
