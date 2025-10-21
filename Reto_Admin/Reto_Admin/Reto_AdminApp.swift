//
//  Reto_AdminApp.swift
//  Reto_Admin
//
//  Created by Mauricio on 22/09/25.
//

import SwiftUI

@main
struct Reto_AdminApp: App {
    @StateObject private var router = AdminRouter()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
