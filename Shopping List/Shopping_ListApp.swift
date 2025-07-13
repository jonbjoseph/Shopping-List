//
//  Shopping_ListApp.swift
//  Shopping List
//
//  Created by Jonathan Joseph on 7/13/25.
//

import SwiftUI

@main
struct Shopping_ListApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
