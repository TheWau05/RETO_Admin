//
//  Siguenteturno.swift
//  Reto_Admin
//
//  Created by 박진혁 on 10/21/25.
//

import Foundation


struct TurnoDTO: Decodable {
    let id: Int
    let usrId: Int
    let scheduledDate: Date
    let status: Bool
    let prescriptionId: String?
    let comentariosReceta: String?
    let comentariosCancelacion: String?

    enum CodingKeys: String, CodingKey {
        case id                = "Id"
        case usrId             = "Usr_Id"
        case scheduledDate     = "Scheduled_Date"
        case status            = "Status"
        case prescriptionId    = "Perscription_Id"
        case comentariosReceta = "Comentarios_Receta"
        case comentariosCancelacion = "Comentarios_Cancelacion"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id     = try c.decode(Int.self,    forKey: .id)
        usrId  = try c.decode(Int.self,    forKey: .usrId)
        status = try c.decode(Bool.self,   forKey: .status)
        prescriptionId         = try? c.decode(String.self, forKey: .prescriptionId)
        comentariosReceta      = try? c.decode(String.self, forKey: .comentariosReceta)
        comentariosCancelacion = try? c.decode(String.self, forKey: .comentariosCancelacion)

        let raw = try c.decode(String.self, forKey: .scheduledDate)
        guard let parsed = DateFormatter.rfc1123.date(from: raw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .scheduledDate, in: c,
                debugDescription: "Expected RFC1123 date like 'Mon, 20 Oct 2025 15:47:43 GMT', got: \(raw)"
            )
        }
        scheduledDate = parsed
    }
}

extension DateFormatter {
    static let rfc1123: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return df
    }()
}


struct Record: Identifiable, Hashable {
    let id: Int
    var perscriptionId: String
    var comentariosReceta: String?
    var date: Date
    var isDone: Bool
}


enum TurnosAPI {
    static let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/turnos/next30")!

    static func fetchNext30() async throws -> [Record] {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let items = try JSONDecoder().decode([TurnoDTO].self, from: data)

        return items.map { dto in
            Record(
                id: dto.id,
                perscriptionId: dto.prescriptionId ?? "—",
                comentariosReceta: dto.comentariosReceta,
                date: dto.scheduledDate,
                isDone: dto.status
            )
        }
    }
}
