//
//  AdminRouter.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import SwiftUI

enum AdminTab: Hashable { case dashboard, abrirCerrar, historial, estadistica }
enum AdminRoute: Hashable { case detalleHistorial(id: String) }

final class AdminRouter: ObservableObject {
    @Published var selected: AdminTab = .dashboard

    // Un path por tab para evitar ambigüedades
    @Published var dashboardPath = NavigationPath()
    @Published var abrirCerrarPath = NavigationPath()
    @Published var historialPath = NavigationPath()
    @Published var estadisticaPath = NavigationPath()

    func push(_ route: AdminRoute, on tab: AdminTab) {
        switch tab {
        case .dashboard: dashboardPath.append(route)
        case .abrirCerrar: abrirCerrarPath.append(route)
        case .historial: historialPath.append(route)
        case .estadistica: estadisticaPath.append(route)
        }
    }

    func popToRoot(_ tab: AdminTab) {
        switch tab {
        case .dashboard: dashboardPath = NavigationPath()
        case .abrirCerrar: abrirCerrarPath = NavigationPath()
        case .historial: historialPath = NavigationPath()
        case .estadistica: estadisticaPath = NavigationPath()
        }
    }

    func switchTo(_ tab: AdminTab) {
        selected = tab
        popToRoot(tab)
    }
}
