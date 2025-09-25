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

            // DASHBOARD
            NavigationStack(path: binding(for: .dashboard)) {
                DashboardAdminView()
            }
            .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }
            .tag(AdminTab.dashboard)

            // ABRIR CERRAR
            NavigationStack(path: binding(for: .abrirCerrar)) {
                AbrirCerrarVentanillaPadView(api: apiContainer.client)
            }
            .tabItem { Label("Abrir Cerrar", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            .tag(AdminTab.abrirCerrar)

            // HISTORIAL
            NavigationStack(path: binding(for: .historial)) {
                HistorialAdminView()
            }
            .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
            .tag(AdminTab.historial)

            // ESTADISTICA
            NavigationStack(path: binding(for: .estadistica)) {
                EstadisticaVentanillaView(api: apiContainer.client)
            }
            .tabItem { Label("Estadistica", systemImage: "gearshape") }
            .tag(AdminTab.estadistica)
        }
        .tint(AdminColors.marca)
        .environmentObject(admin)
        .environmentObject(apiContainer)
        .environmentObject(router)
        // cada vez que cambias de tab limpias el stack del destino
        .onChange(of: router.selected) { newTab in
            router.popToRoot(newTab)
        }
    }

    // helper para enlazar cada path del diccionario
    private func binding(for tab: AdminTab) -> Binding<NavigationPath> {
        Binding(
            get: { router.paths[tab] ?? NavigationPath() },
            set: { router.paths[tab] = $0 }
        )
    }
}

