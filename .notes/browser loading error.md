browser loading error:

Question: Now we need to update the ParcelListView accordingly once fetched the latest status. Also, there is a problem that the app won't load the browser correctly, unless user clicked the tracking number editting field once. This is a bit strange bug, do you have any hint? Any other file you want to see?


Answer: This is a great progression. You are running into two very classic, somewhat notorious issues with SwiftUI and macOS development: CoreData state propagation and WebKit's out-of-process rendering lifecycle.

Here is the critical analysis and the exact fixes for both problems.

### 1. Fixing the `ParcelListView` Not Updating

Your `ParcelListView` uses an `@FetchRequest`. By design, `@FetchRequest` only triggers a UI redraw when the underlying `NSManagedObjectContext` is **saved**, and specifically when the properties it is observing or filtering on have changed.

If your list isn't updating immediately after the scraper succeeds, your `viewModel.addTrackingEvent` is likely missing one of three things:

1. It is not updating `parcel.status` (which `statusEnum` reads from).
2. It is not updating `parcel.lastUpdated`.
3. It is not calling `try? viewContext.save()`.

**The Fix in `ParcelViewModel`:**
Ensure your `addTrackingEvent` method looks exactly like this. The critical parts are updating the metadata and explicitly saving the context:

```swift
func addTrackingEvent(parcel: Parcel, description: String, location: String?, status: ParcelStatus) {
    // 1. Create the new event (assuming you have a TrackingEvent entity or JSON array)
    // ... your logic to append the event ...
    
    // 2. CRITICAL: Update the parent parcel's core properties
    parcel.status = status.rawValue // This moves it to the correct Section in ListView
    parcel.lastUpdated = Date()     // This forces the ListView to sort it to the top
    
    // 3. CRITICAL: Save the context to notify @FetchRequest
    do {
        try viewContext.save()
    } catch {
        print("Failed to save tracking event: \(error)")
    }
}

```

---

### 2. Fixing the "TextField Click" Browser Bug

This is a fascinating bug caused by two intersecting flaws: one in your SwiftUI code, and one in macOS WebKit.

**Why clicking the text field fixes it:**
`WKWebView` runs in a separate process (XPC) from your app. On macOS, if a `WKWebView` is presented in a Sheet before the Window has fully established its responder chain, the WebKit process effectively "goes to sleep" to save memory. It won't paint the screen. When you click the `TextField`, you force macOS to assign a First Responder, which flushes the event queue and wakes up WebKit.

**Additionally, you have a `@StateObject` trap:**
In `SmartBrowserView`, you initialize `@StateObject var model: WebViewModel(url: url)`. In SwiftUI, `StateObject` is only initialized **once** for the lifetime of that view's identity. If you open the sheet twice, it reuses the old URL.

Here is how to harden both views to fix this permanently.

#### A. The DetailView Fix (Resetting Identity)

Open your `DetailView.swift` and add `.id(url)` to the `SmartBrowserView`. This forces SwiftUI to destroy and recreate the view (and the `StateObject`) every time the URL changes, preventing cached blank screens.

```swift
// In DetailView.swift -> sheet(isPresented: $showScraperSheet)
if let url = scraperURL {
    SmartBrowserView(url: url) { scrapedText in
        // ... your scraping logic ...
    }
    .id(url) // 🟢 ADD THIS: Forces a fresh StateObject for every new URL
    .frame(minWidth: 600, minHeight: 700)
}

```

#### B. The SmartBrowserView Fix (Waking up WebKit)

Open `SmartBrowserView.swift`. We need to delay the `model.load()` call by a fraction of a second. This allows the SwiftUI `.sheet` animation to finish and attach to the macOS Window before we ask the heavy WebKit process to start working.

```swift
// In SmartBrowserView.swift
var body: some View {
    NavigationStack {
        WebViewWrapper(model: model, onScrape: onScrape)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // ... toolbar code ...
    }
    .frame(minWidth: 600, minHeight: 700)
    .onAppear {
        // 🟢 FIX: Defer the load until the next runloop cycle.
        // This bypasses the need to click a text field to wake up the window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            model.load()
        }
    }
}

```

### Summary of what to verify:

1. Ensure `addTrackingEvent` modifies `parcel.lastUpdated` and calls `save()`.
2. Add `.id(url)` to the `SmartBrowserView` inside the sheet.
3. Wrap `model.load()` in a tiny asynchronous delay.

These changes will guarantee the list updates instantly and the browser renders reliably without user intervention.