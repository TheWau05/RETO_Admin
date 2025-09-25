//
//  APIModels.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

struct TurnoAverageHour: Codable, Identifiable {
    var id: String { hourStart.iso8601 }
    let hourStart: Date
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double

    enum CodingKeys: String, CodingKey {
        case hourStart = "HourStart"
        case avgServiceMinutes = "AvgServiceDuration_Minutes"
        case avgWaitMinutes = "AvgWaitTime_Minutes"
    }
}

struct TurnosComparisonItem: Codable, Identifiable {
    var id: String { period + hourStart.iso8601 }
    let period: String
    let hourStart: Date
    let turnosCount: Int

    enum CodingKeys: String, CodingKey {
        case period = "Period"
        case hourStart = "HourStart"
        case turnosCount = "TurnosCount"
    }
}

struct AheadCount: Codable { let aheadCount: Int }

struct EmployeeAvg: Codable, Identifiable {
    var id: Int { empId }
    let empId: Int
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double

    enum CodingKeys: String, CodingKey {
        case empId = "Emp_Id"
        case avgServiceMinutes = "AvgServiceMinutes"
        case avgWaitMinutes = "AvgWaitMinutes"
    }
}

struct VentanillaAvg: Codable, Identifiable {
    var id: Int { ventanillaId }
    let ventanillaId: Int
    let avgServiceMinutes: Double
    let avgWaitMinutes: Double

    enum CodingKeys: String, CodingKey {
        case ventanillaId = "Ventanilla_Id"
        case avgServiceMinutes = "AvgServiceMinutes"
        case avgWaitMinutes = "AvgWaitMinutes"
    }
}

extension DateFormatter {
    static let apiISO8601: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .formatted(DateFormatter.apiISO8601)
        return d
    }()
}

extension Date {
    var iso8601: String { DateFormatter.apiISO8601.string(from: self) }
}
