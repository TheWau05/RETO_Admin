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
    func createEmergencyTurno(username: String) async throws -> String


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
    func createEmergencyTurno(username: String) async throws -> String { throw APIError.unimplemented }


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

// MARK: - Forzar Turno de Emergencia
extension HTTPAdminAPI {
    func createEmergencyTurno(username: String) async throws -> String {
        // Endpoint completo
        let url = baseURL.appendingPathComponent("turnos/emergency")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Body JSON
        let body: [String: String] = ["username": username]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        // Petición
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.requestFailed(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw NSError(domain: "HTTPAdminAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Falló con código \(http.statusCode): \(raw)"
            ])
        }

        // Parseo del resultado como texto legible
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        } else if let str = String(data: data, encoding: .utf8) {
            return str
        } else {
            return "Turno de emergencia creado exitosamente"
        }
    }
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

// MARK: - FORMATTER GLOBAL RFC1123 (para todas las fechas de Flask)
let Olirfc1123Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

func OlilocalDate(from dateString: String) -> Date {
    guard let parsed = Olirfc1123Formatter.date(from: dateString) else { return Date() }
    // Flask marca “GMT” pero envía hora local → compensamos +offset
    let offset = TimeZone.current.secondsFromGMT()
    return parsed.addingTimeInterval(TimeInterval(offset))
}

// MARK: - Modelos y llamadas personalizadas

struct HistorialUs: Codable, Identifiable {
    let id = UUID()
    let pacienteName: String
    let perscriptionId: String
    let endTimeString: String

    var endTime: Date {
        OlilocalDate(from: endTimeString)
    }

    enum CodingKeys: String, CodingKey {
        case pacienteName = "PacienteName"
        case perscriptionId = "Perscription_Id"
        case endTimeString = "End_Time"
    }
}

struct NumVentanilla: Codable, Identifiable, Hashable {
    let Id: Int
    let Disponible: Bool
    let Emp_Id: Int?
    let Estatus: String
    var id: Int { Id }
}

func fetchHistorial(fecha: Date, ventanillaId: Int) async throws -> [HistorialUs] {
    let dateFmt = DateFormatter()
    dateFmt.dateFormat = "yyyy-MM-dd"
    let fechaString = dateFmt.string(from: fecha)
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/ventanillas/\(ventanillaId)/history?fecha=\(fechaString)") else {
        throw URLError(.badURL)
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode([HistorialUs].self, from: data)
}

func fetchAllVentanillas() async throws -> [NumVentanilla] {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/ventanillas") else {
        throw URLError(.badURL)
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode([NumVentanilla].self, from: data)
}

// MARK: - Reporte de Desempeño

struct Empleado: Codable, Identifiable, Hashable {
    let Id: Int
    let Name: String
    let Last_Name1: String
    var fullName: String { "\(Name) \(Last_Name1)" }
    var id: Int { Id }
}

struct PerformanceSummary: Codable {
    let TotalTurnosAtendidos: Int
    let TiempoPromedioPorTurno: Int
}

struct PerformanceDetail: Codable, Identifiable {
    let TurnoId: Int
    let Start_Time: String
    let End_Time: String?
    let Duracion_Minutos: Int?
    let Ventanilla_Id: Int

    var startDate: Date { OlilocalDate(from: Start_Time) }
    var endDate: Date? {
        guard let end = End_Time else { return nil }
        return OlilocalDate(from: end)
    }

    var id: Int { TurnoId }
}

struct PerformanceReport: Codable {
    let summary: PerformanceSummary
    let details: [PerformanceDetail]
}

func fetchPerformanceReport(employeeId: Int, startDate: Date, endDate: Date) async throws -> PerformanceReport {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let startStr = fmt.string(from: startDate)
    let endStr = fmt.string(from: endDate)

    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/employees/\(employeeId)/performance?startDate=\(startStr)&endDate=\(endStr)") else {
        throw APIError.badURL
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw APIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? -1)
    }
    return try JSONDecoder().decode(PerformanceReport.self, from: data)
}

func fetchAllEmployees() async throws -> [Empleado] {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/employees") else {
        throw APIError.badURL
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw APIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? -1)
    }
    return try JSONDecoder().decode([Empleado].self, from: data)
}

func formattedDate(from dateString: String) -> String {
    guard let parsed = Olirfc1123Formatter.date(from: dateString) else { return dateString }
    let local = OlilocalDate(from: dateString)
    let display = DateFormatter()
    display.locale = Locale(identifier: "es_MX")
    display.timeZone = .current
    display.dateFormat = "d 'de' MMMM 'de' yyyy, HH:mm"
    return display.string(from: local)
}

struct UsuarioLogin: Codable {
    let message: String
    let username: String?
    let permissions: String?
    let empid: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case username
        case permissions
        case empid
    }
}

func fetchLogin(username: String, password: String) async throws -> UsuarioLogin {
    guard let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/admin/auth/login") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let body: [String: String] = ["username": username, "password": password]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200:
        return try JSONDecoder().decode(UsuarioLogin.self, from: data)
    case 400:
        throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Faltan campos requeridos"])
    case 401:
        throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario o contraseña incorrectos"])
    default:
        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error inesperado"])
    }
}
