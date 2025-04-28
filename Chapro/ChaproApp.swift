//
//  ChaproApp.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import SwiftUI

@main
struct ChaproApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
