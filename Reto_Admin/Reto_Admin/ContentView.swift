//
//  ContentView.swift
//  Reto_Admin
//
//  Created by Mauricio on 22/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var admin = AdminManager()

    var body: some View {
        TabView {
            NavigationStack { DashboardAdminView() }
                .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }

            NavigationStack { HistorialAdminView() }
                .tabItem { Label("Historia de Ventanilla", systemImage: "list.bullet.rectangle") }

            NavigationStack { AdminView() }
                .tabItem { Label("Admin", systemImage: "gearshape") }
        }
        .environmentObject(admin)
    }
}

#Preview {
    ContentView()
}
