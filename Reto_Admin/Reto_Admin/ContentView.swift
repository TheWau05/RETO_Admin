//
//  ContentView.swift
//  Reto_Admin
//
//  Created by Mauricio on 22/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var apiContainer = APIContainer(
        client: HTTPAdminAPI(baseURL: URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!)
    )
    @StateObject private var router = AdminRouter()
    @StateObject private var admin = AdminManager()

    var body: some View {
        TabView(selection: $router.selected) {

            NavigationStack(path: $router.dashboardPath) {
                DashboardAdminView() // <- sin API
            }
            .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }
            .tag(AdminTab.dashboard)

            NavigationStack(path: $router.abrirCerrarPath) {
                AbrirCerrarVentanillaPadView(api: apiContainer.client) // <- única que usa API real
            }
            .tabItem { Label("Abrir Cerrar", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            .tag(AdminTab.abrirCerrar)

            NavigationStack(path: $router.historialPath) {
                HistorialAdminView() // <- visual
            }
            .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
            .tag(AdminTab.historial)

            NavigationStack(path: $router.estadisticaPath) {
                EstadisticaVentanillaView() // <- visual
            }
            .tabItem { Label("Estadistica", systemImage: "gearshape") }
            .tag(AdminTab.estadistica)
        }
        .tint(AdminColors.marca)
        .environmentObject(router)
        .environmentObject(admin)
        .onChange(of: router.selected) { router.popToRoot($0) }
    }
}
