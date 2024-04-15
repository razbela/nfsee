//
//  nfseeApp.swift
//  nfsee
//
//  Created by Raz Belahusky on 15/04/2024.
//

import SwiftUI

@main
struct nfseeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
