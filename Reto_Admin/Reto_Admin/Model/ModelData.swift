//
//  ModelData.swift
//  dsdasd
//
//  Created by 박진혁 on 9/23/25.
//


import Foundation
import SwiftUI



struct Ventanilla: Identifiable, Hashable {
    let id = UUID()
    var nombre: String
    var abierta: Bool
}

struct EventoVentanilla: Identifiable, Hashable {
    let id = UUID()
    let fecha: Date
    let nombre: String
    let accion: String
}

struct HistorialAdmin: Identifiable {
    var id: UUID = .init()
    var ventanillaID: Int
    var idReceta: String
    var horaAtencion: Date
}

func obtenerHistorial() -> [HistorialAdmin] {
    [
        HistorialAdmin(ventanillaID: 1, idReceta: "REC-98765", horaAtencion: Date()),
        HistorialAdmin(ventanillaID: 2, idReceta: "REC-98766", horaAtencion: Date().addingTimeInterval(-1800)),
        HistorialAdmin(ventanillaID: 2, idReceta: "REC-98767", horaAtencion: Date().addingTimeInterval(-3600)),
        HistorialAdmin(ventanillaID: 3, idReceta: "REC-98768", horaAtencion: Date().addingTimeInterval(-5400)),
        HistorialAdmin(ventanillaID: 3, idReceta: "REC-98769", horaAtencion: Date().addingTimeInterval(-7200)),
        HistorialAdmin(ventanillaID: 3, idReceta: "REC-98755", horaAtencion: Date().addingTimeInterval(-86400)),
        HistorialAdmin(ventanillaID: 1, idReceta: "REC-98750", horaAtencion: Date().addingTimeInterval(-90000)),
    ]
}

var historialDeVentanilla: [HistorialAdmin] = obtenerHistorial()


final class AdminManager: ObservableObject {
    @Published var ventanillas: [Ventanilla] = [
        .init(nombre: "Ventanilla 1", abierta: true),
        .init(nombre: "Ventanilla 2", abierta: false),
        .init(nombre: "Ventanilla 3", abierta: true),
        .init(nombre: "Ventanilla 4", abierta: false),
    ]

    @Published var historial: [EventoVentanilla] = []

    func abrirCerrar(_ v: Ventanilla) {
        guard let idx = ventanillas.firstIndex(of: v) else { return }
        ventanillas[idx].abierta.toggle()
        let accion = ventanillas[idx].abierta ? "Abierta" : "Cerrada"
        historial.insert(.init(fecha: Date(),
                               nombre: ventanillas[idx].nombre,
                               accion: accion), at: 0)
    }

    func abrirTodas() {
        for i in ventanillas.indices where !ventanillas[i].abierta {
            ventanillas[i].abierta = true
            historial.insert(.init(fecha: Date(),
                                   nombre: ventanillas[i].nombre,
                                   accion: "Abierta"), at: 0)
        }
    }

    func cerrarTodas() {
        for i in ventanillas.indices where ventanillas[i].abierta {
            ventanillas[i].abierta = false
            historial.insert(.init(fecha: Date(),
                                   nombre: ventanillas[i].nombre,
                                   accion: "Cerrada"), at: 0)
        }
    }

    var abiertasCount: Int { ventanillas.filter(\.abierta).count }
    var cerradasCount: Int { ventanillas.count - abiertasCount }
}

extension Color {
    static var marca: Color { Color(red: 1/255, green: 104/255, blue: 138/255) }
    static var acento: Color { Color(red: 255/255, green: 153/255, blue: 0/255) }
    static var panel: Color { Color(red: 102/255, green: 102/255, blue: 102/255) }
    static var tabGray: Color { Color(UIColor.systemGray5) }
    static var headerGray: Color { Color(UIColor.systemGray5) }
    static var textPrimary: Color { Color(UIColor.label) }
}


struct VentanillaCitas: Identifiable, Hashable {
    let id = UUID()
    var nombre: String
    var citas: Int
}

final class CitasStore: ObservableObject {
    @Published var items: [VentanillaCitas] = [
        .init(nombre: "Ventanilla 1", citas: 12),
        .init(nombre: "Ventanilla 2", citas: 8),
        .init(nombre: "Ventanilla 3", citas: 16),
        .init(nombre: "Ventanilla 4", citas: 5)
    ]

    var totalCitas: Int { items.reduce(0) { $0 + $1.citas } }
    var maxPorVentanilla: Int { items.map(\.citas).max() ?? 0 }
}

