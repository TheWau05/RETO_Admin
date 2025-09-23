//
//  ModelData.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//

import Foundation

func obtenerHistorial() -> [HistorialAdmin] {
    let listaHistorial: [HistorialAdmin] = [
        HistorialAdmin(ventanillaID: 1, idReceta: "REC-98765", horaAtencion: Date()),
        HistorialAdmin(ventanillaID: 2, idReceta: "REC-98766", horaAtencion: Date().addingTimeInterval(-1800)),
        HistorialAdmin(ventanillaID: 3, idReceta: "REC-98767", horaAtencion: Date().addingTimeInterval(-3600)),
        HistorialAdmin(ventanillaID: 1, idReceta: "REC-98768", horaAtencion: Date().addingTimeInterval(-5400)),
        HistorialAdmin(ventanillaID: 2, idReceta: "REC-98769", horaAtencion: Date().addingTimeInterval(-7200)),

        HistorialAdmin(ventanillaID: 3, idReceta: "REC-98755", horaAtencion: Date().addingTimeInterval(-86400)),
        HistorialAdmin(ventanillaID: 1, idReceta: "REC-98750", horaAtencion: Date().addingTimeInterval(-90000))
    ]
    
    return listaHistorial
}

var historialDeVentanilla = obtenerHistorial()
