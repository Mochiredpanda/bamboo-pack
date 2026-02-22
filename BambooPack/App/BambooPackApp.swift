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
        .commands {
            BambooPackCommands()
        }
    }
}