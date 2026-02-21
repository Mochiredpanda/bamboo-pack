import SwiftUI

@main
struct BambooPackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About BambooPack") {
                    NSApplication.shared
                        .orderFrontStandardAboutPanel(
                            options: [
                                .applicationName: "BambooPack",
                                .credits: NSAttributedString(
                                    string: "Copyright © 2026, RedPanda Mochi\nLicensed under the MIT license. See LICENSE file.",
                                    attributes: [
                                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                                        .foregroundColor: NSColor.secondaryLabelColor
                                    ]
                                ),
                                .version: "0.9.0-beta",
                            ]
                        )
                }
                .keyboardShortcut(",")
            }
        }
    }
}
