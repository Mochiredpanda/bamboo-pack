import SwiftUI
import Combine

@main
struct BambooPackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
        WindowGroup("Tracking Browser", id: "SmartBrowser", for: URL.self) { $url in
            if let url = url {
                SmartBrowserView(url: url) { scrapedText in
                    // Note: Consider replacing this NotificationCenter broadcast 
                    // with a strongly typed dependency (e.g., a shared View Model)
                    TrackingUpdateService.shared.didScrapeData.send((url: url, text: scrapedText))
                }
            } else {
                Text("No URL Provided")
            }
        }
        .windowResizability(.contentSize)
        .commands {
            BambooPackCommands()
        }
    }
}