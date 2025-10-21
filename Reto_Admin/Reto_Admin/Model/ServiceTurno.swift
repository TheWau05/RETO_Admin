//
//  ServiceTurno.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//
import Foundation

private struct EmployeeMiniSnap: Codable, Hashable { let id: Int; let name: String }
private struct ACVStateSnapshot: Codable {
    var asignados: [Int: EmployeeMiniSnap] = [:]
    var estados:   [Int: Bool] = [:]
    var ventanillaSeleccionada: Int = 1
}
private let kACVDefaultsKey = "AbrirCerrarVentanilla_State_v2"

private func loadContextFromSnapshot() -> (ventId: Int?, empId: Int?) {
    guard let data = UserDefaults.standard.data(forKey: kACVDefaultsKey),
          let snap = try? JSONDecoder().decode(ACVStateSnapshot.self, from: data) else {
        return (nil, nil)
    }
    let vent = snap.ventanillaSeleccionada
    let emp  = snap.asignados[vent]?.id
    return (vent, emp)
}

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

    
    func startService() async throws -> (turnoId: Int, ventanillaId: Int) {
        let ctx = loadContextFromSnapshot()
        guard let ventId = ctx.ventId else {
            throw NSError(domain: "CTX", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No hay ventanilla seleccionada. Abre la pestaña “Abrir Cerrar” y configúrala."
            ])
        }

        var req = URLRequest(url: base.appendingPathComponent("/service/start"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["ventanilla_id": ventId]
        if let emp = ctx.empId { body["emp_id"] = emp }

        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let b = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "HTTP", code: http.statusCode, userInfo: ["body": b])
        }

        
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            if let msg = root["message"] as? String, !msg.isEmpty {
                if msg.lowercased().contains("no está disponible")
                    || msg.lowercased().contains("no existe")
                    || msg.lowercased().contains("error") {
                    throw NSError(domain: "BACK", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
                }
            }

            if let arr = root["assignments"] as? [[String: Any]],
               let first = arr.first,
               let tid = first["turno_id"] as? Int,
               let vid = first["ventanilla_id"] as? Int {
                return (tid, vid)
            }

            if let tid = root["turno_id"] as? Int,
               let vid = root["ventanilla_id"] as? Int {
                return (tid, vid)
            }
        }

        throw NSError(domain: "PARSE", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Respuesta inesperada de /service/start"])
    }

   
    func finishService(turnoId: Int, ventanillaId: Int) async throws {
        let ctx = loadContextFromSnapshot()

        var req = URLRequest(url: base.appendingPathComponent("/service/finish"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "turno_id": turnoId,
            "ventanilla_id": ventanillaId
        ]
        if let emp = ctx.empId { body["emp_id"] = emp }

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
