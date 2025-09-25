//
//  APIModels.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//
import Foundation

struct ProcedureEnvelope<T: Decodable>: Decodable {
    let procedure: String?
    let data: T?
    let output: T?
}

extension DateFormatter {
    static let apiPlain: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
    static let apiZ: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
    }()
    static let apiMillis: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return f
    }()
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            if let d1 = DateFormatter.apiPlain.date(from: s) { return d1 }
            if let d2 = DateFormatter.apiZ.date(from: s) { return d2 }
            if let d3 = DateFormatter.apiMillis.date(from: s) { return d3 }
            throw DecodingError.dataCorrupted(.init(codingPath: dec.codingPath, debugDescription: "bad date"))
        }
        return d
    }()
}

extension Date { var iso8601: String { DateFormatter.apiPlain.string(from: self) } }

struct TurnoAverageHour: Codable, Identifiable {
    var id: String { hourStart.iso8601 }
    let hourStart: Date
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double
}

struct TurnosComparisonItem: Codable, Identifiable {
    var id: String { period + hourStart.iso8601 }
    let period: String
    let hourStart: Date
    let turnosCount: Int
}

struct TurnoHourBin: Codable, Identifiable {
    var id: String { hourStart.iso8601 }
    let hourStart: Date
    let turnosCount: Int
}

struct AheadCount: Codable {
    let turnoId: Int?
    let turnosAhead: Int
}

struct EmployeeAvg: Codable, Identifiable {
    var id: Int { empId }
    let empId: Int
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double
}

struct EmployeeBasic: Codable, Identifiable, Hashable {
    let id: Int
    let name: String

    enum K: String, CodingKey { case Id, Name, Last_Name1, last_name1, first_name }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        let i = try c.decode(Int.self, forKey: .Id)
        let n = (try? c.decode(String.self, forKey: .Name)) ?? (try? c.decode(String.self, forKey: .first_name)) ?? ""
        let ln = (try? c.decode(String.self, forKey: .Last_Name1)) ?? (try? c.decode(String.self, forKey: .last_name1)) ?? ""
        id = i
        name = ln.isEmpty ? n : "\(n) \(ln)"
    }
}

struct VentanillaAvg: Codable, Identifiable {
    var id: Int { ventanillaId }
    let ventanillaId: Int
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double
}

struct UserTurn: Codable, Identifiable {
    var id: Int { turnoId ?? idRaw ?? -1 }
    let idRaw: Int?
    let turnoId: Int?
    let scheduledDate: String?
    let status: Int?
}

typealias NextTurno = UserTurn
