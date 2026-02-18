Here is the comprehensive technical specification and implementation plan for your app. This document consolidates the UI improvements, the "Tier 2" tracking logic, and the business strategy into a single source of truth.

```markdown
# Parcel App: Technical Design Document (MVP)

## 1. Executive Summary
This application is a native macOS tracking tool designed for indie/power users. Unlike standard trackers that rely on expensive enterprise APIs, this app utilizes a **"Human-Assisted Scraping" (Tier 2)** approach. This ensures 100% reliability, zero server costs for the developer, and privacy for the user.

**Core Philosophy:**
* **Frontend:** Native, fluid, and "Mac-like" (SwiftUI).
* **Backend:** Local-first (CoreData). No central server.
* **Tracking Engine:** `WKWebView` injection (User acts as the authentication agent).

---

## 2. Business Logic & Tiered Strategy

We are bypassing the "Free API" trap by leveraging the user's device capabilities.

| Tier | Strategy | Implementation | Target Audience |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Fallback)** | **Manual Deep Link** | Button opens Safari (`ups.com/track...`). User checks manually. | Users with obscure carriers. |
| **Tier 2 (Core)** | **Smart Scraper** | App opens in-app browser sheet. User solves Captcha. App auto-closes on success. | **The MVP Standard.** |
| **Tier 3 (Paid)** | **Background Push** | Server-side Aggregator API (17TRACK/AfterShip) checks every 4h. | Future Subscription model. |

---

## 3. Data Model Architecture

**Entity:** `Parcel`
* `trackingNumber` (String)
* `carrier` (String) - *Enum bridged to String*
* `status` (String) - *Enum: ordered, shipped, delivered, exception*
* `title` (String)
* `notes` (String)
* `lastUpdated` (Date)
* `historyJson` (String) - *Stores full history blob*
* **[NEW]** `estimatedDeliveryDate` (Date) - *Crucial for the "Hero" UI urgency.*

---

## 4. Frontend Specifications (SwiftUI)

### A. The "Intelligent" List Row (`ParcelRowView`)
*Goal: Concise, scannable information. No raw tracking numbers.*

* **Left:** Dynamic Icon (Truck for moving, Box for delivered, Cart for ordered).
* **Middle:** Title + Small Carrier Pill.
* **Right:** **Relative Time** (e.g., "Tomorrow", "In 3 days") or Status (e.g., "Delivered").

```swift
// Key Logic: Relative Date Formatting
if let date = parcel.estimatedDeliveryDate {
    let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    if days == 0 { Text("Arriving Today").foregroundColor(.orange) }
    else if days == 1 { Text("Tomorrow") }
    else { Text("In \(days) days") }
}

```

### B. The "Native" Add Sheet (`AddParcelSheet`)

*Goal: Responsive window that feels at home on macOS.*

* **Window Management:**
* `frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity)`
* `frame(minHeight: 400, idealHeight: 550, maxHeight: .infinity)`


* **Form Style:** `.grouped`
* **Logic:** `TextEditor` (Notes) set to `.frame(maxHeight: .infinity)` to grow with the window.

### C. The Detail View (`DetailView`)

*Goal: Editable fields without "Edit Mode" + Hero Card.*

* **Structure:**
1. **Hero Card:** Custom `VStack` with `.background(Color(NSColor.controlBackgroundColor))`.
* *Fix:* Must apply `.listRowSeparator(.hidden)` AND `.listSectionSeparator(.hidden)`.


2. **Shipment Details:** Direct `TextField` bindings to CoreData object.
3. **History:** "View Full History" button triggers a secondary Sheet.



---

## 5. The Core Engine: "Magic Browser" (Tier 2)

This is the replacement for the expensive API.

### Workflow

1. User clicks **"Refresh"** on a parcel.
2. App presents a `.sheet` containing a `WebViewContainer`.
3. **WebView** loads `carrier.com/track?id=...`.
4. **Observer:** `WKNavigationDelegate` waits for `didFinish`.
5. **Injection:** App runs `document.body.innerText`.
6. **Extraction:** App parses text. If "Delivered" or "In Transit" is found:
* Update CoreData.
* **Auto-dismiss the sheet.**
* Show "Toast" success message.



### Implementation Concept: The Intelligent Regex Parser

```swift
struct ScrapedStatus {
    var status: ParcelStatus
    var date: String?
}

func parseTrackingStatus(from text: String) -> ScrapedStatus? {
    let cleanText = text.lowercased()
    
    // 1. Anchor & Capture Strategy
    // Look for "Status" keyword, then grab the next 5-20 words
    let statusPattern = /status\s*[:|-]?\s*([a-z\s]+)/ 
    
    if let match = try? statusPattern.firstMatch(in: cleanText) {
        let captured = String(match.1)
        if captured.contains("delivered") { return .init(status: .delivered, date: nil) }
        if captured.contains("transit") { return .init(status: .shipped, date: nil) }
    }
    
    // 2. Fallback: Heuristic Keyword Search
    if cleanText.contains("out for delivery") { 
        return .init(status: .shipped, date: "Today") 
    }
    
    return nil
}

```

### Future Proofing: `selectors.json`

To prevent the app from breaking when FedEx changes their website, fetch a JSON file from GitHub on app launch:

```json
{
  "ups": {
    "url": "[https://www.ups.com/track?tracknum=](https://www.ups.com/track?tracknum=)%@",
    "success_keywords": ["delivered", "transit"],
    "selector_override": "#st_status" 
  }
}

```

---

## 6. Implementation Roadmap

### Phase 1: The "Perfect" UI (Current Focus)

* [x] Refactor `AddParcelSheet` to be resizable.
* [x] Implement `DetailView` with Hero Card & Inline Editing.
* [ ] Fix List Row to remove Tracking Number and add Relative Time logic.

### Phase 2: The "Magic" Browser

* [ ] Build `WebViewContainer` (SwiftUI wrapper for WKWebView).
* [ ] Implement the `parseTrackingStatus` regex logic.
* [ ] Connect "Refresh" button in Detail View to trigger the WebView sheet.

### Phase 3: Polish

* [ ] Add "Toast" notifications (e.g., "Updated 2 parcels").
* [ ] Implement the `selectors.json` remote config fetcher.

```

```