# Project Vision: Bamboo Pack (Red Panda Tracker)

## 1. Project Overview
**Goal:** specific native macOS/iOS application to track parcel deliveries and returns.
**Core Philosophy:** "Tiny, Native, Beautiful." No feature bloat. No maps. Focus on list organization and state management.
**Theme:** Red Panda (Warm rust/orange accents, playful but clean UI).
**Sync:** iCloud (CloudKit) via Core Data.

## 2. Technical Stack
* **Language:** Swift 6.
* **UI Framework:** SwiftUI.
* **Data Persistence:** Core Data with `NSPersistentCloudKitContainer` (Auto-sync).
* **Target OS:** macOS 14+ (Sonoma/Sequoia), iOS 17+.
* **Architecture:** MVVM.
* **Networking:** Modern Swift Concurrency (`async/await`).

## 3. Data Model (Core Data Entities)

### Entity: `Parcel`
* `id`: UUID
* `title`: String (User defined, e.g., "New Keyboard")
* `trackingNumber`: String?
* `carrier`: String? (detected via API or manual)
* `orderNumber`: String? (for pre-tracking phase)
* `notes`: String?
* `status`: Integer (Enum mapping, see below)
* `direction`: Integer (Enum: 0 = Incoming, 1 = Outgoing/Return)
* `lastUpdated`: Date
* `archived`: Boolean (Default false)

### Enums
**StatusEnum:**
1.  **Ordered:** Order placed, waiting for fulfillment.
2.  **Shipped:** Tracking number added, waiting for scan.
3.  **InTransit:** Moving through network.
4.  **Delivered:** Final destination reached.
5.  **Exception:** Customs hold/Lost.

## 4. Business Logic & Feature Requirements

### Feature A: The "Add" Flow (Smart Detection)
1.  User enters text.
2.  **Regex Logic:** Agent must implement regex patterns for major carriers (UPS, FedEx, USPS, DHL) to auto-detect the carrier based on the tracking number format.
3.  **API Integration:** Create a protocol `TrackingService`. Initially, implement a mock service or a free tier wrapper (e.g., 17TRACK or AfterShip free API) to fetch carrier name.
    * *Constraint:* If API fails, fallback to manual carrier selection.

### Feature B: Order Lifecycle Management
The app organizes items based on their logical state, not just shipping location.
* **Incoming:** Things I bought.
* **Outgoing:** Things I am selling or sending to friends.
* **Returns:** A special subset of "Outgoing."
    * *Logic:* If a user marks an Incoming item as "Return," the app should prompt to create a linked Outgoing entry with the return tracking number.

### Feature C: iCloud Sync
* Must use `NSPersistentCloudKitContainer`.
* Changes on macOS must reflect on iOS within moments.
* Handle `NSPersistentCloudKitContainer.Event` to show sync status (e.g., "Syncing..." in the footer).

## 5. UI/UX Guidelines (Big Sur+ Style)

### macOS
* **Sidebar:** Standard `NavigationSplitView`.
    * Categories: "Incoming", "Outgoing", "Archive".
* **List Style:** `SidebarListStyle`.
* **Detail View:** Clean form. No maps.
* **Visuals:**
    * Use SF Symbols.
    * **Accent Color:** "Red Panda Rust" (Hex: #C65D3B).
    * **App Icon:** A minimalist vector Red Panda face.

### iOS
* Standard TabView or NavigationStack.
* Haptic feedback on status changes.

## 6. Implementation Plan (Step-by-Step for AI Agent)

**Phase 1: Skeleton & Data**
1.  Set up Xcode project with Core Data + CloudKit enabled.
2.  Create the `Parcel` entity in the `.xcdatamodeld` file.
3.  Create the `ParcelViewModel` to handle CRUD operations.

**Phase 2: The Logic**
1.  Implement `CarrierDetector` (Regex/Pattern matching class).
2.  Implement `StatusManager` to handle state transitions (e.g., moving from Ordered to Shipped).

**Phase 3: The UI**
1.  Build `SidebarView` using `Smart Filters` (Predicate-based fetch requests).
2.  Build `AddParcelSheet` with the carrier auto-detection logic.
3.  Apply the "Red Panda" color theme and clean typography.

**Phase 4: API & Polish**
1.  Connect the `TrackingService` to a real API (user to provide API Key in Settings).
2.  Test iCloud syncing between Simulator and Mac.

## 7. Instructions for the Agent
* **Critical:** Do not use 3rd party UI libraries. Use pure SwiftUI.
* **Critical:** Ensure all database calls are performed on the background context, UI updates on MainActor.
* When generating code, prioritize readability and separate logic into Services (e.g., `CarrierService`, `SyncService`).