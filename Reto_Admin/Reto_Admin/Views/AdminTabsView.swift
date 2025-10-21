//
//  AdminTabsView.swift
//  Reto_Admin
//
//  Created by Mauricio on 21/10/25.
//

import SwiftUI

struct AdminTabsView: View {
    @Binding var permisos: String
    @Binding var idempleado: Int
    @Binding var loggedIn: Bool

    @StateObject private var apiContainer = APIContainer(
        client: HTTPAdminAPI(baseURL: URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!)
    )
    @StateObject private var router = AdminRouter()
    @StateObject private var admin  = AdminManager()

    var body: some View {
        ZStack {
            if loggedIn {
                // ✅ Solo muestra las tabs si está logueado
                TabView(selection: $router.selected) {
                    
                    NavigationStack(path: $router.abrirCerrarPath) {
                        AbrirCerrarVentanillaPadView(api: apiContainer.client)
                    }
                    .tabItem { Label("Abrir/Cerrar", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                    .tag(AdminTab.abrirCerrar)
                    
                    NavigationStack(path: $router.dashboardPath) {
                        DashboardAdminView(loggedIn: $loggedIn)
                    }
                    .tabItem { Label("Chatbot", systemImage: "square.grid.2x2.fill") }
                    .tag(AdminTab.dashboard)

                    NavigationStack(path: $router.historialPath) {
                        HistorialAdminView()
                    }
                    .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }
                    .tag(AdminTab.historial)

                    NavigationStack(path: $router.rendimientoPath) {
                        RendimientoEmpleadoView()
                    }
                    .tabItem { Label("Rendimiento", systemImage: "person.text.rectangle") }
                    .tag(AdminTab.rendimiento)

                    NavigationStack(path: $router.estadisticaPath) {
                        EstadisticaVentanillaView()
                    }
                    .tabItem { Label("Estadística", systemImage: "gearshape") }
                    .tag(AdminTab.estadistica)
                }
                .tint(AdminColors.marca)
                .environmentObject(router)
                .environmentObject(admin)
                .onChange(of: router.selected) { router.popToRoot($0) }
                .globalExecutiveBot()

            } else {
                // ✅ Pantalla de login fuera del TabView
                NavigationStack(path: $router.inicioPath) {
                    LoginAdminView(loggedIn: $loggedIn,
                                   idempleado: $idempleado,
                                   permisos: $permisos)
                }
            }
        }
    }
}

#Preview {
    AdminTabsView(permisos: .constant("Admin"), idempleado: .constant(12), loggedIn: .constant(true))
}
