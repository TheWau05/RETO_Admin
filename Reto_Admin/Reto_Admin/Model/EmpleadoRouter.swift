//
//  EmpleadoRouter.swift
//  Reto_Admin
//
//  Created by Mauricio on 21/10/25.
//

import SwiftUI

enum EmpleadoTab: Hashable { case TurnoRapidoAdminView, nextturn, inicio, abrircerrar }

final class EmpleadoRouter: ObservableObject {
    @Published var selected: EmpleadoTab = .TurnoRapidoAdminView

    @Published var togglePath   = NavigationPath()
    @Published var nextTurnPath = NavigationPath()
    @Published var inicioPath = NavigationPath()
    @Published var abrirCerrarPath = NavigationPath()

    func popToRoot(_ tab: EmpleadoTab) {
        switch tab {
        case .abrircerrar: abrirCerrarPath = .init()
        case .inicio:  inicioPath  = .init()
        case .TurnoRapidoAdminView:   togglePath = .init()
        case .nextturn: nextTurnPath = .init()
        }
    }
    func switchTo(_ tab: EmpleadoTab) {
        DispatchQueue.main.async {
            self.selected = tab
        }
    }
}
