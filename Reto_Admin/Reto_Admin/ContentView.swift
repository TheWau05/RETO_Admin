//
//  ContentView.swift
//  Reto_Admin
//
//  Created by Mauricio on 22/09/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AdminRouter
    
    @State private var loggedIn: Bool = false
    @State private var idempleado: Int = 0
    @State private var permisos: String = ""
    
    var body: some View {
        if permisos == "Admin" {
            AdminTabsView(permisos: $permisos, idempleado: $idempleado, loggedIn: $loggedIn)
        } else if permisos == "Emp" {
            EmpleadoTabView(permisos: $permisos, idempleado: $idempleado, loggedIn: $loggedIn)
        } else {
            LoginAdminView(loggedIn: $loggedIn,
                           idempleado: $idempleado,
                           permisos: $permisos)
        }
    }
}
