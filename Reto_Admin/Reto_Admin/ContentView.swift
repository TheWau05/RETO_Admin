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

            NavigationStack { AbrirCerrarVentanillaPadView() }
                .tabItem { Label("Abrir Cerrar", systemImage: "rectangle.portrait.on.rectangle.portrait") }

            NavigationStack { HistorialAdminView() }
                .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }

            NavigationStack { EstadisticaVentanillaView() }
                .tabItem { Label("Estadistica", systemImage: "gearshape") }
        }
        .tint(AdminColors.marca)
        .environmentObject(admin)
    }
}

#Preview { ContentView() }
