# Feature Spec: Smart Share Extension ("Bamboo Catch")

## 1. Overview
**Goal:** specific workflow to allow users to "forward" tracking information from other apps (Mail, Messages, Safari) directly into Bamboo Pack without manual copy-pasting.
**Philosophy:** "Zero-Click Intelligence." The app doesn't snoop; the user explicitly hands data to the app via the native OS Share Sheet.
**Privacy:** 100% Client-Side. No data is sent to a server for parsing.

## 2. User Workflow (The "Happy Path")

### Scenario A: The Email Text
1.  User opens an email confirmation in Apple Mail or Gmail.
2.  User highlights the text block containing the tracking number (or the whole email body if short).
3.  User taps **Share** -> selects **Bamboo Pack**.
4.  **System:** The extension launches a small modal sheet (not the full app).
5.  **System:** Auto-detects the tracking number and carrier from the text.
6.  User confirms the "Title" (e.g., "New Shoes") and taps **Save**.
7.  **Feedback:** The sheet closes with a success haptic. The item is now in the main app's iCloud database.

### Scenario B: The "Track Package" Link
1.  User sees a "Track Your Package" button in an email or website.
2.  User long-presses the link -> **Share**.
3.  **System:** Extension parses the URL (e.g., `fedex.com/track?numbers=12345`).
4.  **System:** Extracts `12345` and identifies `FedEx`.
5.  User taps **Save**.

## 3. Technical Architecture

### Component: Share Extension
* **Target Type:** iOS/macOS Share Extension.
* **Activation Rules:**
    * `NSExtensionActivationRule`: Support `public.plain-text` and `public.url`.

### Data Persistence (Critical)
Since Extensions run in a separate process from the Main App, they cannot access the main app's sandbox.
1.  **App Groups:** Must enable App Groups capability (e.g., `group.com.yourname.bamboopack`).
2.  **Core Data:** The `NSPersistentCloudKitContainer` must point to the shared App Group container URL, not the default document directory.
    * *Constraint:* Ensure the Core Data stack is initialized identically in both the Main App and the Extension.

### Parsing Logic (The "Brain")
Do not write complex custom parsers if possible. Use Apple's native NLP tools.
1.  **NSDataDetector:** Use `NSTextCheckingResult.CheckingType.transitInformation` (if available/reliable) or `.link`.
2.  **Regex Fallback:** If `NSDataDetector` fails, run the custom Regex patterns defined in the main app (shared via a Swift Package or shared file).
    * *Refinement:* If the input is a URL, parse query parameters for keys like `track`, `id`, `num`, `numbers`.

## 4. Implementation Steps for AI Agent

**Step 1: Project Setup**
1.  Add a new Target: **Share Extension**.
2.  Enable **App Groups** in "Signing & Capabilities" for both targets.
3.  Refactor the `PersistenceController` (Core Data) to use the App Group URL.

**Step 2: The Parsing Engine (Shared Logic)**
Create a shared Swift file (Target Membership = Both App & Extension) named `SmartParser.swift`.
```swift
struct ParsedResult {
    let trackingNumber: String
    let carrier: CarrierType?
    let confidence: Double
}

class SmartParser {
    static func parse(text: String) -> ParsedResult? {
        // 1. Try NSDataDetector
        // 2. Try Regex matching for known carriers (UPS/FedEx/USPS)
        // 3. Return best match
    }
    
    static func parse(url: URL) -> ParsedResult? {
        // 1. Check host (e.g., fedex.com)
        // 2. Extract query items
    }
}


Step 3: The Extension UI (SwiftUI)
The extension should not look like a standard system dialog. It should look like Bamboo Pack.

Wrap the ShareViewController to host a SwiftUI View.

View State:

Loading: While parsing.

Success: Show a "Draft Card" with the detected carrier logo (Red Panda style) and an input field for the Item Name.

Error: "No tracking number found."

Action: "Save" button writes to Core Data context and calls extensionContext?.completeRequest.

5. Constraints & Edge Cases
Performance: Parsing must happen on a background queue, but it must be fast (< 1 second).

Conflict: If the user shares a URL that is not a tracking link (e.g., a YouTube video), show a polite "No shipment info found" error rather than crashing.

Offline: The extension must work without internet. It relies on Regex/String parsing, not API calls.