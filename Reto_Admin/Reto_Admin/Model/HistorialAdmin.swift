//
//  HistorialAdmin.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//

import Foundation

struct HistorialAdmin : Identifiable {
    let id = UUID()
    let ventanillaID: Int
    let idReceta: String
    let horaAtencion: Date
}
