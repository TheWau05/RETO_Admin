//
//  ContentView.swift
//  Reto_Admin
//
//  Created by Mauricio on 22/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var admin = AdminManager()
    @StateObject private var apiContainer = APIContainer(client: MockAdminAPI())
    @StateObject private var router = AdminRouter()

    var body: some View {
        TabView(selection: $router.selected) {

            NavigationStack(path: $router.dashboardPath) {
                DashboardAdminView()
            }
            .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }
            .tag(AdminTab.dashboard)

            NavigationStack(path: $router.abrirCerrarPath) {
                AbrirCerrarVentanillaPadView(api: apiContainer.client)
            }
            .tabItem { Label("Abrir Cerrar", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            .tag(AdminTab.abrirCerrar)

            NavigationStack(path: $router.historialPath) {
                HistorialAdminView()
            }
            .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
            .tag(AdminTab.historial)

            NavigationStack(path: $router.estadisticaPath) {
                EstadisticaVentanillaView(api: apiContainer.client)
            }
            .tabItem { Label("Estadistica", systemImage: "gearshape") }
            .tag(AdminTab.estadistica)
        }
        .tint(AdminColors.marca)
        .environmentObject(admin)
        .environmentObject(apiContainer)
        .environmentObject(router)
        .onChange(of: router.selected) { router.popToRoot($0) }
    }
}

#Preview {
    ContentView()
        .environmentObject(AdminManager())
        .environmentObject(APIContainer(client: MockAdminAPI()))
        .environmentObject(AdminRouter())
}

