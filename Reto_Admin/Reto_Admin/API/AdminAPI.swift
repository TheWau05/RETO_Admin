//
//  AdminAPI.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

// MARK: - Contrato
protocol AdminAPI {
    // Stats / tablas (NO usados por Abrir/Cerrar; dejar para que compile el resto)
    func avgTimesByEmployee() async throws -> [EmployeeAvg]
    func avgTimesByVentanilla() async throws -> [VentanillaAvg]
    func turnos24hAverages() async throws -> [TurnoAverageHour]
    func turnos24hComparison() async throws -> [TurnosComparisonItem]
    func turnos24hBins() async throws -> [TurnoHourBin]

    // Turnos (NO usados por Abrir/Cerrar)
    func aheadCount(turnoId: Int) async throws -> AheadCount
    func getNextTurno() async throws -> NextTurno
    func userTurns(userId: Int) async throws -> [UserTurn]

    // Ventanillas / Servicio (SÍ usamos open/close)
    func openVentanilla(ventanillaId: Int, empId: Int) async throws
    func closeVentanilla(ventanillaId: Int) async throws
    func serviceVentanilla(ventanillaId: Int, empId: Int) async throws
    func startService(ventanillaId: Int, turnoId: Int) async throws

    // Compat de UI antigua (lo dejo pero con default que llama open/close)
    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws

    // Empleados (SÍ usamos)
    func unassignedEmployees() async throws -> [EmployeeBasic]
}

enum APIError: Error {
    case badURL
    case requestFailed(Int)
    case decodingFailed
    case unimplemented
}

// MARK: - Defaults para TODO lo que no usa Abrir/Cerrar
extension AdminAPI {
    func avgTimesByEmployee() async throws -> [EmployeeAvg] { throw APIError.unimplemented }
    func avgTimesByVentanilla() async throws -> [VentanillaAvg] { throw APIError.unimplemented }
    func turnos24hAverages() async throws -> [TurnoAverageHour] { throw APIError.unimplemented }
    func turnos24hComparison() async throws -> [TurnosComparisonItem] { throw APIError.unimplemented }
    func turnos24hBins() async throws -> [TurnoHourBin] { throw APIError.unimplemented }

    func aheadCount(turnoId: Int) async throws -> AheadCount { throw APIError.unimplemented }
    func getNextTurno() async throws -> NextTurno { throw APIError.unimplemented }
    func userTurns(userId: Int) async throws -> [UserTurn] { throw APIError.unimplemented }

    func serviceVentanilla(ventanillaId: Int, empId: Int) async throws { throw APIError.unimplemented }
    func startService(ventanillaId: Int, turnoId: Int) async throws { throw APIError.unimplemented }

    // Default útil: si alguien aún llama esto, lo mapeo a open/close con empId=1
    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws {
        if closed { try await closeVentanilla(ventanillaId: ventanillaId) }
        else { try await openVentanilla(ventanillaId: ventanillaId, empId: 1) }
    }

    // Si nadie lo implementa: por claridad fallar explícito
    func unassignedEmployees() async throws -> [EmployeeBasic] { throw APIError.unimplemented }
}

// MARK: - Cliente HTTP SOLO Abrir/Cerrar
final class HTTPAdminAPI: AdminAPI {
    struct Paths {
        let prefix = "" // cambia a "/api" si tu Flask tiene prefijo
        func open(_ v: Int, _ e: Int) -> String { "\(prefix)/ventanillas/open/\(v)/\(e)" }
        func close(_ v: Int)             -> String { "\(prefix)/ventanillas/close/\(v)" }
        var unassigned: String           { "\(prefix)/employees/unassigned" }
    }

    let baseURL: URL
    let session: URLSession
    private let paths = Paths()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // Empleados
    func unassignedEmployees() async throws -> [EmployeeBasic] {
        try await getWrapped(paths.unassigned)
    }

    // Ventanillas
    func openVentanilla(ventanillaId: Int, empId: Int) async throws {
        try await postVoid(paths.open(ventanillaId, empId))
    }
    func closeVentanilla(ventanillaId: Int) async throws {
        try await postVoid(paths.close(ventanillaId))
    }

    // Infra mínima
    private struct EmptyBody: Encodable {}
    private func decodeWrapped<T: Decodable>(_ data: Data) throws -> T {
        let dec = JSONDecoder.api
        if let t = try? dec.decode(T.self, from: data) { return t }
        if let env = try? dec.decode(ProcedureEnvelope<T>.self, from: data) {
            if let d = env.data { return d }
            if let o = env.output { return o }
        }
        throw APIError.decodingFailed
    }
    private func getWrapped<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError.requestFailed((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try decodeWrapped(data)
    }
    private func postVoid(_ path: String) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(EmptyBody())
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError.requestFailed((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }
}


struct HistorialUs: Codable, Identifiable {
    let id = UUID()
    let pacienteName: String
    let perscriptionId: String
    let endTime: Date // Cambiado a Date para manejarlo mejor en Swift

    enum CodingKeys: String, CodingKey {
        case pacienteName = "PacienteName"
        case perscriptionId = "Perscription_Id"
        case endTime = "End_Time"
    }
}

func fetchHistorial(fecha: Date, ventanillaId: Int) async throws -> [HistorialUs] {
    // 1. Convertimos la fecha de Swift a un String en formato YYYY-MM-DD para la URL
    let urlDateFormatter = DateFormatter()
    urlDateFormatter.dateFormat = "yyyy-MM-dd"
    let fechaString = urlDateFormatter.string(from: fecha)

    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/ventanillas/\(ventanillaId)/history?fecha=\(fechaString)") else {
        throw URLError(.badURL)
    }
    
    // 2. Hacemos la llamada de red
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 3. Creamos un decodificador con el formato de fecha que envía la API
    let decoder = JSONDecoder()
    let apiDateFormatter = DateFormatter()
    apiDateFormatter.locale = Locale(identifier: "en_US_POSIX")
    apiDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz" // Formato RFC 1123 que usa Flask
    decoder.dateDecodingStrategy = .formatted(apiDateFormatter)
    
    // 4. Decodificamos el JSON en nuestro arreglo de [HistorialUs]
    return try decoder.decode([HistorialUs].self, from: data)
}

