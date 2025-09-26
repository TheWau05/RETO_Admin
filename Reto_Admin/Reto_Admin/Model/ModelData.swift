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












// Hacer structs. Dalr codable, identifiable
// MARK: - For /stats/turnos/24h-comparison
struct Turnos24ComparisonItem: Codable, Identifiable {
    let id = UUID()
    let hourStart: Date
    let period: String
    let turnosCount: Int

    enum CodingKeys: String, CodingKey {
        case hourStart = "HourStart"
        case period = "Period"
        case turnosCount = "TurnosCount"
    }
}

// MARK: - For /stats/turnos/24h-averages
struct Turno24AverageHour: Codable, Identifiable {
    let id = UUID()
    let hourStart: Date
    let avgServiceMinutes: Double?
    let avgWaitMinutes: Double?
    
    enum CodingKeys: String, CodingKey {
        case hourStart = "HourStart"
        case avgServiceMinutes = "AvgServiceDuration_Minutes"
        case avgWaitMinutes = "AvgWaitTime_Minutes"
    }
}

// MARK: - For /ventanillas/status
struct VentanillaStatus: Codable, Identifiable {
    let id: Int
    let disponible: Bool
    let empId: Int?
    let estatus: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case disponible = "Disponible"
        case empId = "Emp_Id"
        case estatus = "Estatus"
    }
}




// Función para darle formato a la hora
let rfc1123Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

// Hacer fetch
// MARK: - Función para traer turnos desde la API
func fetchTurnos24ComparisonItem() async throws -> [Turnos24ComparisonItem] {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/turnos/24h-comparison") else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(rfc1123Formatter)
    return try decoder.decode([Turnos24ComparisonItem].self, from: data)
}

// MARK: - Función para traer promedio turnos desde la API
func fetchTurno24AverageHour() async throws -> [Turno24AverageHour] {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/turnos/24h-averages") else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(rfc1123Formatter)
    return try decoder.decode([Turno24AverageHour].self, from: data)
}

// MARK: - Función para traer ventanillas desde la API
func fetchVentanillasStatus() async throws -> [VentanillaStatus] {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/ventanillas/status") else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    return try decoder.decode([VentanillaStatus].self, from: data)
}

// Crear estructura para acomodar turnos en bins
struct TurnosComparisonBin: Identifiable {
    let id = UUID()
    let hour: Int       // 0–23
    let period: String  // "Past" or "Future"
    let count: Int
}

// Crear estructura para acomodar turnos AVGs en bins
struct TurnosAverageBin: Identifiable {
    let id = UUID()
    let hour: Int
    let type: String // "Espera" or "Servicio"
    let value: Double
}
