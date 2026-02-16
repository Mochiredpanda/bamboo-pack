//
//  BambooPackApp.swift
//  BambooPack
//
//  Created by Jiyu He on 2/15/26.
//

import SwiftUI
import CoreData

@main
struct BambooPackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
