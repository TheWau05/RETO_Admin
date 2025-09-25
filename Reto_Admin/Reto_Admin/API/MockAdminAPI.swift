//
//  MockAdminAPI.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

final class MockAdminAPI: AdminAPI {
    func turnos24hAverages() async throws -> [TurnoAverageHour] {
        let now = Date()
        return (0..<24).map { i in
            let h = Calendar.current.date(byAdding: .hour, value: i, to: now)!
            return TurnoAverageHour(hourStart: h, avgServiceMinutes: Double(Int.random(in: 8...15)), avgWaitMinutes: Double(Int.random(in: 8...15)))
        }
    }

    func turnos24hComparison() async throws -> [TurnosComparisonItem] {
        let now = Date()
        let past = (0..<24).map { i in
            TurnosComparisonItem(period: "Past", hourStart: Calendar.current.date(byAdding: .hour, value: -i, to: now)!, turnosCount: Int.random(in: 0...12))
        }
        let future = (1...24).map { i in
            TurnosComparisonItem(period: "Future", hourStart: Calendar.current.date(byAdding: .hour, value: i, to: now)!, turnosCount: Int.random(in: 0...12))
        }
        return past + future
    }

    func aheadCount(turnoId: Int) async throws -> AheadCount {
        AheadCount(aheadCount: Int.random(in: 0...10))
    }

    func avgTimesByEmployee() async throws -> [EmployeeAvg] {
        (1...6).map { i in EmployeeAvg(empId: i, avgServiceMinutes: Double.random(in: 9...14), avgWaitMinutes: Double.random(in: 9...14)) }
    }

    func avgTimesByVentanilla() async throws -> [VentanillaAvg] {
        (1...4).map { i in VentanillaAvg(ventanillaId: i, avgServiceMinutes: Double.random(in: 9...14), avgWaitMinutes: Double.random(in: 9...14)) }
    }

    func setVentanillaState(ventanillaId: Int, hourStart: Date, closed: Bool) async throws {}
}
