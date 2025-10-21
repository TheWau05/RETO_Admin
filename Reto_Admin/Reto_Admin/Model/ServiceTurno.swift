//
//  ServiceTurno.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//
import Foundation

// ====== Modelos mínimos para leer el snapshot guardado por Abrir/Cerrar ======
private struct EmployeeMini: Codable, Hashable {
    let id: Int
    let name: String
}
private struct ACVStateSnapshot: Codable {
    var asignados: [Int: EmployeeMini] = [:] // ventanilla -> empleado
    var estados:   [Int: Bool] = [:]         // ventanilla -> cerrada(true)/abierta(false)
    var ventanillaSeleccionada: Int = 1
}
private let kACVDefaultsKey = "AbrirCerrarVentanilla_State_v2"

// ====== Servicio Turno ======
final class ServicioTurnoAdmin {

    private let base = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!
    private let keyTurno      = "turno_cache_id_v1"
    private let keyVentanilla = "turno_cache_vent_v1"

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 45
        cfg.timeoutIntervalForResource = 90
        return URLSession(configuration: cfg)
    }()

    // MARK: - Contexto desde Abrir/Cerrar
    /// Lee de UserDefaults la ventanilla seleccionada y el empleado asignado a esa ventanilla.
    private func loadContextFromAbrirCerrar() -> (ventId: Int?, empId: Int?) {
        guard let data = UserDefaults.standard.data(forKey: kACVDefaultsKey),
              let snap = try? JSONDecoder().decode(ACVStateSnapshot.self, from: data) else {
            return (nil, nil)
        }
        let v = snap.ventanillaSeleccionada
        let e = snap.asignados[v]?.id
        return (v, e)
    }

    // MARK: - Cache local de turno activo
    func loadCached() -> (turno: Int?, ventanilla: Int?) {
        (UserDefaults.standard.object(forKey: keyTurno) as? Int,
         UserDefaults.standard.object(forKey: keyVentanilla) as? Int)
    }
    func saveCached(turno: Int, ventanilla: Int) {
        UserDefaults.standard.set(turno, forKey: keyTurno)
        UserDefaults.standard.set(ventanilla, forKey: keyVentanilla)
    }
    func clearCached() {
        UserDefaults.standard.removeObject(forKey: keyTurno)
        UserDefaults.standard.removeObject(forKey: keyVentanilla)
    }

    // MARK: - API

    /// POST /service/start
    /// Body esperado (según tus mensajes del backend):
    /// { "ventanilla_id": Int, "emp_id": Int? }
    func startService() async throws -> (turnoId: Int, ventanillaId: Int) {
        let ctx = loadContextFromAbrirCerrar()
        guard let ventId = ctx.ventId else {
            throw NSError(domain: "CTX", code: -1, userInfo: [
                NSLocalizedDescriptionKey:
                    "No hay ventanilla seleccionada. Abre la pestaña 'Abrir Cerrar' y selecciona una ventanilla/empleado."
            ])
        }

        var req = URLRequest(url: base.appendingPathComponent("/service/start"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["ventanilla_id": ventId]
        if let empId = ctx.empId { body["emp_id"] = empId } // opcional si el backend lo usa
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let b = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "HTTP", code: http.statusCode, userInfo: ["body": b])
        }

        // Acepta varios formatos de respuesta
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let msg = root["message"] as? String, !msg.isEmpty {
                throw NSError(domain: "BACK", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            if let arr = root["assignments"] as? [[String: Any]],
               let first = arr.first,
               let tid = first["turno_id"] as? Int,
               let vid = first["ventanilla_id"] as? Int {
                return (tid, vid)
            }
            if let tid = root["turno_id"] as? Int, let vid = root["ventanilla_id"] as? Int {
                return (tid, vid)
            }
        }
        throw NSError(domain: "PARSE", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Respuesta inesperada de /service/start"])
    }

    /// POST /service/finish
    /// Body esperado: { "turno_id": Int, "ventanilla_id": Int, "emp_id": Int? }
    func finishService(turnoId: Int, ventanillaId: Int) async throws {
        let ctx = loadContextFromAbrirCerrar()

        var req = URLRequest(url: base.appendingPathComponent("/service/finish"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "turno_id": turnoId,
            "ventanilla_id": ventanillaId
        ]
        if let empId = ctx.empId { body["emp_id"] = empId } // opcional si tu backend lo valida
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let b = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "HTTP", code: http.statusCode, userInfo: ["body": b])
        }

        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = root["message"] as? String,
           msg.lowercased().contains("error") {
            throw NSError(domain: "BACK", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
