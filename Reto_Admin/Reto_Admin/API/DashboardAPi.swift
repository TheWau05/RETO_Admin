//
//  DashboardAPi.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/25/25.
//

import Foundation


private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let d = try? decode(Double.self, forKey: key) { return d }
        if let s = try? decode(String.self, forKey: key), let d = Double(s) { return d }
        throw DecodingError.dataCorruptedError(forKey: key, in: self,
                                               debugDescription: "Expected Double or numeric String")
    }
}

// MARK: - Ventanillas

/// Row returned by /stats/ventanillas/avg-times
struct VentanillaAvg: Decodable, Identifiable {
    var id: Int                // Ventanilla_Id
    var avgService: Double     // AvgServiceMinutes
    var avgWait: Double        // AvgWaitMinutes

    enum K: String, CodingKey {
        case ventId = "Ventanilla_Id"
        case svc    = "AvgServiceMinutes"
        case wait   = "AvgWaitMinutes"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        id         = try c.decode(Int.self, forKey: .ventId)
        avgService = try c.decodeFlexibleDouble(forKey: .svc)
        avgWait    = try c.decodeFlexibleDouble(forKey: .wait)
    }
}

// MARK: - Empleados

/// Row returned by /stats/employees/avg-times
struct EmpleadoAvg: Decodable, Identifiable {
    var id: Int            // Emp_Id
    var avgService: Double // AvgServiceMinutes
    var avgWait: Double    // AvgWaitMinutes

    enum K: String, CodingKey {
        case empId = "Emp_Id"
        case svc   = "AvgServiceMinutes"
        case wait  = "AvgWaitMinutes"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        id         = try c.decode(Int.self, forKey: .empId)
        avgService = try c.decodeFlexibleDouble(forKey: .svc)
        avgWait    = try c.decodeFlexibleDouble(forKey: .wait)
    }
}

// MARK: - Networking VM (fetches both endpoints)

@MainActor
final class AvgTimesViewModel: ObservableObject {
    @Published var ventRows: [VentanillaAvg] = []
    @Published var empRows: [EmpleadoAvg] = []
    @Published var errorMessage: String?

    private let ventURL = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/ventanillas/avg-times")!
    private let empURL  = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/employees/avg-times")!

    func fetch() {
        errorMessage = nil
        fetchVentanillas()
        fetchEmpleados()
    }

    private func fetchVentanillas() {
        URLSession.shared.dataTask(with: ventURL) { data, resp, err in
            if let err = err { return self.fail("Red (ventanillas): \(err.localizedDescription)") }
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return self.fail("HTTP no válido (ventanillas)")
            }
            guard let data = data else { return self.fail("Sin datos (ventanillas)") }

            do {
                let rows = try JSONDecoder().decode([VentanillaAvg].self, from: data)
                DispatchQueue.main.async { self.ventRows = rows }
            } catch {
                #if DEBUG
                if let raw = String(data: data, encoding: .utf8) { print("⚠️ Ventanillas JSON:\n\(raw)") }
                #endif
                self.fail("Error al decodificar (ventanillas): \(error.localizedDescription)")
            }
        }.resume()
    }

    private func fetchEmpleados() {
        URLSession.shared.dataTask(with: empURL) { data, resp, err in
            if let err = err { return self.fail("Red (empleados): \(err.localizedDescription)") }
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return self.fail("HTTP no válido (empleados)")
            }
            guard let data = data else { return self.fail("Sin datos (empleados)") }

            do {
                let rows = try JSONDecoder().decode([EmpleadoAvg].self, from: data)
                DispatchQueue.main.async { self.empRows = rows }
            } catch {
                #if DEBUG
                if let raw = String(data: data, encoding: .utf8) { print("⚠️ Empleados JSON:\n\(raw)") }
                #endif
                self.fail("Error al decodificar (empleados): \(error.localizedDescription)")
            }
        }.resume()
    }

    private func fail(_ msg: String) {
        DispatchQueue.main.async { self.errorMessage = msg }
    }
}
