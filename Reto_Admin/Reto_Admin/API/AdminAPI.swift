//
//  AdminAPI.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

protocol AdminAPI {
    func turnos24hAverages() async throws -> [TurnoAverageHour]
    func turnos24hComparison() async throws -> [TurnosComparisonItem]
    func aheadCount(turnoId: Int) async throws -> AheadCount
    func avgTimesByEmployee() async throws -> [EmployeeAvg]
    func avgTimesByVentanilla() async throws -> [VentanillaAvg]
    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws
}

enum APIError: Error { case badURL, requestFailed, decodingFailed }

final class HTTPAdminAPI: AdminAPI {
    let baseURL: URL
    let session: URLSession
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL; self.session = session
    }

    func turnos24hAverages() async throws -> [TurnoAverageHour] { try await get(path: "/sp_turnos24hAverages") }
    func turnos24hComparison() async throws -> [TurnosComparisonItem] { try await get(path: "/sp_turnos24hComparison") }
    func aheadCount(turnoId: Int) async throws -> AheadCount { try await get(path: "/sp_turnosAhead", query: ["turnoId": "\(turnoId)"]) }
    func avgTimesByEmployee() async throws -> [EmployeeAvg] { try await get(path: "/sp_avgTimesByEmployee") }
    func avgTimesByVentanilla() async throws -> [VentanillaAvg] { try await get(path: "/sp_avgTimesByVentanilla") }

    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws {
        struct Body: Encodable { let ventanillaId: Int; let hourStart: String; let closed: Bool }
        let body = Body(ventanillaId: ventanillaId, hourStart: hourStart.iso8601, closed: closed)
        _ = try await post(path: "/ventanilla/state", body: body) as EmptyResponse
    }

    private struct EmptyResponse: Decodable {}

    private func get<T: Decodable>(path: String, query: [String:String] = [:]) async throws -> T {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else { throw APIError.badURL }
        if !query.isEmpty { comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = comps.url else { throw APIError.badURL }
        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw APIError.requestFailed }
        do { return try JSONDecoder.api.decode(T.self, from: data) } catch { throw APIError.decodingFailed }
    }

    private func post<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw APIError.requestFailed }
        do { return try JSONDecoder.api.decode(R.self, from: data) } catch { throw APIError.decodingFailed }
    }
}

    func turnos24hComparison() async throws -> [TurnosComparisonItem] {
        let now = Date()
        let past = (0..<24).map { i in TurnosComparisonItem(period: "Past",   hourStart: Calendar.current.date(byAdding: .hour, value: -i, to: now)!, turnosCount: Int.random(in: 0...12)) }
        let future = (1...24).map { i in TurnosComparisonItem(period: "Future", hourStart: Calendar.current.date(byAdding: .hour, value:  i, to: now)!, turnosCount: Int.random(in: 0...12)) }
        return past + future
    }
    func aheadCount(turnoId: Int) async throws -> AheadCount { AheadCount(aheadCount: Int.random(in: 0...10)) }
    func avgTimesByEmployee() async throws -> [EmployeeAvg] { (1...6).map { EmployeeAvg(empId: $0, avgServiceMinutes: Double.random(in: 9...14), avgWaitMinutes: Double.random(in: 9...14)) } }
    func avgTimesByVentanilla() async throws -> [VentanillaAvg] { (1...4).map { VentanillaAvg(ventanillaId: $0, avgServiceMinutes: Double.random(in: 9...14), avgWaitMinutes: Double.random(in: 9...14)) } }
    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws {}

