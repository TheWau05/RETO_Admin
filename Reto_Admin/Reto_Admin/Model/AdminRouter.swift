//
//  AdminRouter.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import SwiftUI

enum AdminTab: Hashable { case abrirCerrar, dashboard, historial, rendimiento, estadistica, turnoRapido, inicio }
enum AdminRoute: Hashable { case detalleHistorial(id: String) }

final class AdminRouter: ObservableObject {
    @Published var selected: AdminTab = .abrirCerrar

    @Published var abrirCerrarPath = NavigationPath()
    @Published var dashboardPath = NavigationPath()
    @Published var historialPath = NavigationPath()
    @Published var rendimientoPath = NavigationPath()
    @Published var estadisticaPath = NavigationPath()
    @Published var inicioPath = NavigationPath()

    @Published var turnoRapidoPath = NavigationPath()

    func push(_ route: AdminRoute, on tab: AdminTab) {
        switch tab {
        case .abrirCerrar: abrirCerrarPath.append(route)
        case .inicio:      inicioPath.append(route)
        case .dashboard:   dashboardPath.append(route)
        case .historial:   historialPath.append(route)
        case .rendimiento: rendimientoPath.append(route)
        case .estadistica: estadisticaPath.append(route)
        case .turnoRapido: turnoRapidoPath.append(route)
        }
    }

    func popToRoot(_ tab: AdminTab) {
        switch tab {
        case .abrirCerrar: abrirCerrarPath = NavigationPath()
        case .inicio:      inicioPath = NavigationPath()
        case .dashboard:   dashboardPath = NavigationPath()
        case .historial:   historialPath = NavigationPath()
        case .rendimiento: rendimientoPath = NavigationPath()
        case .estadistica: estadisticaPath = NavigationPath()
        case .turnoRapido: turnoRapidoPath = NavigationPath()
        }
    }

    func switchTo(_ tab: AdminTab) {
        selected = tab
        popToRoot(tab)
    }
}

