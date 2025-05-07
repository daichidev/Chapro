//
//  ChaproApp.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import SwiftUI

@main
struct ChaproApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .defaultSize(width: 1024, height: 800)
        .windowResizability(.automatic)
    }
}
