# AI Jargon Explainer - Xcode Setup Guide (Simplified)

This guide is simplified for testing with a **free Apple ID** on a rented Mac.
No paid developer account needed. No App Groups needed.

## Prerequisites

- A Mac (or rented Mac VPS like MacinCloud, MacStadium, etc.)
- Xcode 15 or 16 (free from Mac App Store)
- Apple ID (free — no $99 developer program needed for simulator testing)
- Gemini API key (free from https://ai.google.dev)

---

## Step 1: Get Your Gemini API Key

1. Go to https://ai.google.dev
2. Sign in with a Google account
3. Click "Get API Key" in the sidebar
4. Create a key (no credit card needed)
5. Copy the key — you'll need it in Step 4

## Step 2: Create the Xcode Project

1. Open **Xcode**
2. **File > New > Project**
3. Select **iOS > App**, click **Next**
4. Fill in:
   - Product Name: `AIJargonExplainer`
   - Team: Select your **Apple ID** (add it first via Xcode > Settings > Accounts if needed)
   - Organization Identifier: `com.RLASAF12` (or anything you like)
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Click **Create**, save anywhere on the Mac

## Step 3: Add the Keyboard Extension Target

1. **File > New > Target**
2. Select **iOS > Custom Keyboard Extension**, click **Next**
3. Product Name: `AIKeyboard`
4. Click **Finish**
5. When prompted "Activate AIKeyboard scheme?" — click **Activate**
6. **IMPORTANT:** Click the **AIKeyboard** target in the left sidebar,
   go to **Signing & Capabilities**, and set the **Team** to your Apple ID

## Step 4: Replace & Add Source Files

### Delete the auto-generated files:
In the left sidebar (Project Navigator), you'll see auto-generated files.
Right-click each one below and choose **Delete > Move to Trash**:

- In `AIJargonExplainer` folder: delete `ContentView.swift` (keep `AIJargonExplainerApp.swift` or delete it too)
- In `AIKeyboard` folder: delete `KeyboardViewController.swift`

### Add the source files from GitHub:
1. Clone or download the repo files to the Mac
2. For the **AIJargonExplainer** target — drag these files into the `AIJargonExplainer` folder in Xcode:
   - `AIJargonExplainer/AIJargonExplainerApp.swift`
   - `AIJargonExplainer/ContentView.swift`

3. For the **AIKeyboard** target — drag these files into the `AIKeyboard` folder in Xcode:
   - `AIKeyboard/KeyboardViewController.swift`
   - `AIKeyboard/KeyboardView.swift`
   - `AIKeyboard/GeminiService.swift`

4. For **Shared** files — drag these into the project (at the top level):
   - `Shared/Constants.swift`
   - `Shared/SharedDefaults.swift`

   **CRITICAL:** When dragging shared files, Xcode shows a dialog. Check BOTH targets:
   - [x] AIJargonExplainer
   - [x] AIKeyboard

   If you missed this, select each shared file in the navigator, open the **File Inspector**
   (right panel icon), and check both targets under **Target Membership**.

### Set your API key:
5. Open `Constants.swift` in Xcode
6. Replace `PASTE_YOUR_GEMINI_API_KEY_HERE` with your actual Gemini API key

## Step 5: Configure the Keyboard Extension Info.plist

Open `AIKeyboard/Info.plist` and verify it has these entries.
If they're missing, add them manually:

```
NSExtension (Dictionary)
  NSExtensionPointIdentifier (String) = com.apple.keyboard-service
  NSExtensionPrincipalClass (String) = $(PRODUCT_MODULE_NAME).KeyboardViewController
  NSExtensionAttributes (Dictionary)
    RequestsOpenAccess (Boolean) = YES
    IsASCIICapable (Boolean) = YES
    PrimaryLanguage (String) = en-US
```

If the keyboard extension was auto-generated with its own Info.plist, you can
replace it with the one from the `AIKeyboard/Info.plist` file in the repo.

## Step 6: Build & Run on Simulator

1. In the top bar, select scheme: **AIJargonExplainer** (not AIKeyboard)
2. Select a simulator: **iPhone 15** or **iPhone 16**
3. Press **Cmd + R** to build and run
4. The main app should open showing the setup instructions and "Test Explain" button
5. Tap **"Test Explain"** to verify the Gemini API works

## Step 7: Test the Keyboard on Simulator

1. After the main app is running, press **Cmd + Shift + H** (Home button)
2. Go to **Settings > General > Keyboard > Keyboards**
3. Tap **Add New Keyboard...**
4. Select **AIKeyboard** under "AIJargonExplainer"
5. Tap **AIKeyboard** and enable **Allow Full Access** > confirm
6. Open **Notes** app or **Safari**
7. Tap a text field to bring up the keyboard
8. Tap the **globe icon** at the bottom-left to cycle keyboards
9. Switch to **AI Explainer** keyboard
10. Tap **"Explain"** to test!

---

## Troubleshooting

### Xcode says "Signing requires a development team"
- Select the target in the left sidebar
- Go to Signing & Capabilities
- Set "Team" to your Apple ID
- Do this for BOTH targets (AIJargonExplainer AND AIKeyboard)

### "No such module" or build errors
- Make sure `Constants.swift` and `SharedDefaults.swift` have target membership
  in BOTH targets (check File Inspector > Target Membership)

### Keyboard doesn't appear in Settings
- Make sure you ran the **AIJargonExplainer** scheme (not AIKeyboard)
- The keyboard extension installs when the main app is installed

### "Full Access is required" in the keyboard
- Go to Settings > General > Keyboard > Keyboards > AIKeyboard > Allow Full Access

### API key not working
- Verify your key at https://ai.google.dev
- Make sure you replaced the placeholder text in Constants.swift
- Free tier: ~15 requests per minute

### Keychain popup appears
- Click "Always Allow" and enter the Mac login password
- This is normal — Xcode needs access to signing certificates

---

## Project Structure

```
AIJargonExplainer/
├── AIJargonExplainer/              (Main App - onboarding & setup)
│   ├── AIJargonExplainerApp.swift  (App entry point)
│   └── ContentView.swift           (Setup UI + test button)
│
├── AIKeyboard/                     (Keyboard Extension - the actual keyboard)
│   ├── KeyboardViewController.swift (UIKit bridge to SwiftUI)
│   ├── KeyboardView.swift          (SwiftUI keyboard UI)
│   ├── GeminiService.swift         (Gemini API network calls)
│   └── Info.plist                  (Extension config: RequestsOpenAccess=true)
│
└── Shared/                         (Shared between both targets)
    ├── Constants.swift             (API key goes here!)
    └── SharedDefaults.swift        (Reads the API key)
```
