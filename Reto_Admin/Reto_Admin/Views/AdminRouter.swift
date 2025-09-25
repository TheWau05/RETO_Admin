//
//  AdminRouter.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import SwiftUI

enum AdminTab: Hashable {
    case dashboard
    case abrirCerrar
    case historial
    case estadistica
}

// Rutas internas por si luego navegas a detalles
enum AdminRoute: Hashable {
    case detalleHistorial(id: String)
}

final class AdminRouter: ObservableObject {
    @Published var selected: AdminTab = .dashboard

    // Un stack por tab
    @Published var paths: [AdminTab: NavigationPath] = [
        .dashboard: NavigationPath(),
        .abrirCerrar: NavigationPath(),
        .historial: NavigationPath(),
        .estadistica: NavigationPath()
    ]

    func push(_ route: AdminRoute, on tab: AdminTab) {
        paths[tab]?.append(route)
    }

    func popToRoot(_ tab: AdminTab) {
        paths[tab] = NavigationPath()
    }

    func switchTo(_ tab: AdminTab) {
        selected = tab
        popToRoot(tab)
    }
}
