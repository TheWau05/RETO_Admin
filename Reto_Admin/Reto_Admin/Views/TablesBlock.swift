//
//  TablesBlock.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 25/09/25.
//

//import SwiftUI
//
//// MARK: - TablesBlock (auto-fetch + optional manual data)
//
///// Card with two compact “spreadsheet” tables: ventanillas + empleados.
///// Use:
/////   - `TablesBlock()`                         -> auto-fetches API data
/////   - `TablesBlock(venRows:empRows:)`        -> renders the rows you pass (no network)
//struct TablesBlock: View {
//    // If these are nil, we'll auto-fetch. If you pass rows, we won't fetch.
//    private let venRowsProp: [[String]]?
//    private let empRowsProp: [[String]]?
//
//    // Headers (defaults match your screenshot/API)
//    var ventHeaders: [String] = ["Ventanilla_Id", "AvgServiceMin_Ven", "AvgWaitMin_Ven"]
//    var empHeaders:  [String] = ["Emp_Id",        "AvgServiceMin",    "AvgWaitMin"]
//
//    // UI state for auto-fetch mode
//    @State private var venRowsState: [[String]] = []
//    @State private var empRowsState: [[String]] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    // MARK: Initializers
//
//    /// Parameterless initializer -> auto-fetch from API
//    init() {
//        self.venRowsProp = nil
//        self.empRowsProp = nil
//    }
//
//    /// Manual rows initializer -> no network
//    init(
//        venRows: [[String]],
//        empRows: [[String]],
//        ventHeaders: [String] = ["Ventanilla_Id", "AvgServiceMin_Ven", "AvgWaitMin_Ven"],
//        empHeaders:  [String] = ["Emp_Id", "AvgServiceMin", "AvgWaitMin"]
//    ) {
//        self.venRowsProp = venRows
//        self.empRowsProp = empRows
//        self.ventHeaders = ventHeaders
//        self.empHeaders = empHeaders
//    }
//
//    // MARK: Derived data
//
//    private var venRowsEffective: [[String]] { venRowsProp ?? venRowsState }
//    private var empRowsEffective: [[String]] { empRowsProp ?? empRowsState }
//    private var shouldFetch: Bool { venRowsProp == nil && empRowsProp == nil }
//
//    // MARK: View
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//
//            if let msg = errorMessage {
//                Text(msg).foregroundColor(.red).font(.footnote)
//            }
//
//            Text("Promedios por ventanilla")
//                .font(.headline)
//                .foregroundColor(Color(.label))
//
//            SpreadsheetTable(headers: ventHeaders, rows: venRowsEffective)
//
//            Text("Promedios por empleado")
//                .font(.headline)
//                .foregroundColor(Color(.label))
//                .padding(.top, 4)
//
//            SpreadsheetTable(headers: empHeaders, rows: empRowsEffective)
//                .frame(maxWidth: 520, alignment: .leading)
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .fill(Color(.systemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
//        )
//        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
//        .redacted(reason: isLoading ? .placeholder : [])
//        .task {
//            guard shouldFetch else { return }
//            await fetchFromAPI()
//        }
//    }
//
//    // MARK: - Networking (local model names to avoid collisions)
//
//    private func fetchFromAPI() async {
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            async let ventanillas = fetchVentanillasTB()
//            async let empleados   = fetchEmpleadosTB()
//
//            let v = try await ventanillas
//            let e = try await empleados
//
//            venRowsState = v.map { [
//                String($0.id),
//                String(format: "%.2f", $0.avgService),
//                String(format: "%.2f", $0.avgWait)
//            ]}
//
//            empRowsState = e.map { [
//                String($0.id),
//                String(format: "%.2f", $0.avgService),
//                String(format: "%.2f", $0.avgWait)
//            ]}
//        } catch {
//            errorMessage = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
//        }
//    }
//
//    private func fetchVentanillasTB() async throws -> [TBVentanillaAvg] {
//        let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/ventanillas/avg-times")!
//        let (data, resp) = try await URLSession.shared.data(from: url)
//        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
//            throw URLError(.badServerResponse)
//        }
//        return try JSONDecoder().decode([TBVentanillaAvg].self, from: data)
//    }
//
//    private func fetchEmpleadosTB() async throws -> [TBEmployeeAvg] {
//        let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/stats/employees/avg-times")!
//        let (data, resp) = try await URLSession.shared.data(from: url)
//        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
//            throw URLError(.badServerResponse)
//        }
//        return try JSONDecoder().decode([TBEmployeeAvg].self, from: data)
//    }
//}
//
//// MARK: - Local Models (renamed, robust Double-or-String decoding)
//
//private struct TBVentanillaAvg: Decodable {
//    let id: Int
//    let avgService: Double
//    let avgWait: Double
//
//    enum K: String, CodingKey {
//        case ventId = "Ventanilla_Id"
//        case svc    = "AvgServiceMinutes"
//        case wait   = "AvgWaitMinutes"
//    }
//
//    init(from decoder: Decoder) throws {
//        let c = try decoder.container(keyedBy: K.self)
//        id         = try c.decode(Int.self, forKey: .ventId)
//        avgService = try Self.flexDouble(c, .svc)
//        avgWait    = try Self.flexDouble(c, .wait)
//    }
//
//    private static func flexDouble(_ c: KeyedDecodingContainer<K>, _ k: K) throws -> Double {
//        if let d = try? c.decode(Double.self, forKey: k) { return d }
//        if let s = try? c.decode(String.self, forKey: k), let d = Double(s) { return d }
//        throw DecodingError.dataCorruptedError(forKey: k, in: c, debugDescription: "Expected Double or numeric String")
//    }
//}
//
//private struct TBEmployeeAvg: Decodable {
//    let id: Int
//    let avgService: Double
//    let avgWait: Double
//
//    enum K: String, CodingKey {
//        case empId = "Emp_Id"
//        case svc   = "AvgServiceMinutes"
//        case wait  = "AvgWaitMinutes"
//    }
//
//    init(from decoder: Decoder) throws {
//        let c = try decoder.container(keyedBy: K.self)
//        id         = try c.decode(Int.self, forKey: .empId)
//        avgService = try Self.flexDouble(c, .svc)
//        avgWait    = try Self.flexDouble(c, .wait)
//    }
//
//    private static func flexDouble(_ c: KeyedDecodingContainer<K>, _ k: K) throws -> Double {
//        if let d = try? c.decode(Double.self, forKey: k) { return d }
//        if let s = try? c.decode(String.self, forKey: k), let d = Double(s) { return d }
//        throw DecodingError.dataCorruptedError(forKey: k, in: c, debugDescription: "Expected Double or numeric String")
//    }
//}
//
//// MARK: - Table view used by the card
//
//private struct SpreadsheetTable: View {
//    let headers: [String]
//    let rows: [[String]]
//
//    private let cols = [
//        GridItem(.flexible(minimum: 90)),
//        GridItem(.flexible(minimum: 140)),
//        GridItem(.flexible(minimum: 140))
//    ]
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header strip
//            LazyVGrid(columns: cols, spacing: 0) {
//                ForEach(headers, id: \.self) { h in
//                    Text(h)
//                        .font(.caption.bold())
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 10)
//                        .background(Color(red: 0.62, green: 0.76, blue: 0.86))
//                        .overlay(
//                            Rectangle()
//                                .fill(Color.white.opacity(0.28))
//                                .frame(height: 1),
//                            alignment: .bottom
//                        )
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//
//            // Body rows
//            VStack(spacing: 0) {
//                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
//                    LazyVGrid(columns: cols, spacing: 0) {
//                        ForEach(row.indices, id: \.self) { i in
//                            Text(row[i])
//                                .font(.caption)
//                                .foregroundColor(Color(.label))
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .padding(.vertical, 8)
//                                .padding(.horizontal, 10)
//                                .background(Color(.secondarySystemBackground))
//                        }
//                    }
//                    Rectangle()
//                        .fill(Color(.separator).opacity(0.35))
//                        .frame(height: 0.6)
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//            .overlay(
//                RoundedRectangle(cornerRadius: 8, style: .continuous)
//                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
//            )
//        }
//    }
//}

import SwiftUI
//
//struct TablesBlock: View {
//    // Optional preloaded data (skip network if provided)
//    private let venRowsProp: [[String]]?
//    private let empRowsProp: [[String]]?
//
//    // Updated headers (now includes employee name)
//    var ventHeaders: [String] = ["Número de Ventanilla", "Tiempo en Servicio", "Tiempo de Espera"]
//    var empHeaders:  [String] = ["Empleado", "Tiempo en Servicio", "Tiempo de Espera"]
//
//    // UI state
//    @State private var venRowsState: [[String]] = []
//    @State private var empRowsState: [[String]] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    // MARK: - Initializers
//
//    init() {
//        self.venRowsProp = nil
//        self.empRowsProp = nil
//    }
//
//    init(
//        venRows: [[String]],
//        empRows: [[String]],
//        ventHeaders: [String] = ["Número de Ventanilla", "Tiempo en Servicio", "Tiempo de Espera"],
//        empHeaders:  [String] = ["Empleado", "Tiempo en Servicio", "Tiempo de Espera"]
//    ) {
//        self.venRowsProp = venRows
//        self.empRowsProp = empRows
//        self.ventHeaders = ventHeaders
//        self.empHeaders = empHeaders
//    }
//
//    // Derived properties
//    private var venRowsEffective: [[String]] { venRowsProp ?? venRowsState }
//    private var empRowsEffective: [[String]] { empRowsProp ?? empRowsState }
//    private var shouldFetch: Bool { venRowsProp == nil && empRowsProp == nil }
//
//    // MARK: - Body
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            if let msg = errorMessage {
//                Text(msg).foregroundColor(.red).font(.footnote)
//            }
//
//            Text("Promedios por ventanilla")
//                .font(.headline)
//                .foregroundColor(Color(.label))
//
//            SpreadsheetTable(headers: ventHeaders, rows: venRowsEffective)
//
//            Text("Promedios por empleado")
//                .font(.headline)
//                .foregroundColor(Color(.label))
//                .padding(.top, 4)
//
//            SpreadsheetTable(headers: empHeaders, rows: empRowsEffective)
//                .frame(maxWidth: 600, alignment: .leading)
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .fill(Color(.systemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
//        )
//        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
//        .redacted(reason: isLoading ? .placeholder : [])
//        .task {
//            guard shouldFetch else { return }
//            await fetchFromAPI()
//        }
//    }
//
//    // MARK: - Fetch Logic
//    private func fetchFromAPI() async {
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            async let ventanillas = fetchVentAvgTimes()
//            async let empleados   = fetchEmpAvgTimes()
//
//            let v = try await ventanillas
//            let e = try await empleados
//
//            // Map data into display-friendly string arrays
//            venRowsState = v.map { [
//                String($0.id),
//                String(format: "%.2f", $0.avgServiceMinutes),
//                String(format: "%.2f", $0.avgWaitMinutes)
//            ]}
//
//            empRowsState = e.map { [
//                $0.empleadoNombre,
//                String(format: "%.2f", $0.avgServiceMinutes),
//                String(format: "%.2f", $0.avgWaitMinutes)
//            ]}
//        } catch {
//            errorMessage = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
//        }
//    }
//}
//
//// MARK: - SpreadsheetTable (unchanged)
//private struct SpreadsheetTable: View {
//    let headers: [String]
//    let rows: [[String]]
//
////    private var cols: [GridItem] {
////        Array(repeating: GridItem(.flexible(minimum: 120)), count: headers.count)
////    }
//    private var cols: [GridItem] {
//        [
//            GridItem(.flexible(minimum: 220, maximum: 300)), // Name
//            GridItem(.flexible(minimum: 100, maximum: 120)), // AvgService
//            GridItem(.flexible(minimum: 100, maximum: 120))  // AvgWait
//        ]
//    }
//
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header strip
//            LazyVGrid(columns: cols, spacing: 0) {
//                ForEach(headers, id: \.self) { h in
//                    Text(h)
//                        .font(.caption.bold())
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 10)
//                        .background(Color(red: 0.62, green: 0.76, blue: 0.86))
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//
//            // Body rows
//            VStack(spacing: 0) {
//                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
//                    LazyVGrid(columns: cols, spacing: 0) {
//                        ForEach(row.indices, id: \.self) { i in
//                            Text(row[i])
//                                .font(.caption)
//                                .foregroundColor(Color(.label))
//                                .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .trailing)
//                                .padding(.vertical, 8)
//                                .padding(.horizontal, 10)
//                                .background(index.isMultiple(of: 2) ?
//                                    Color(.secondarySystemBackground) :
//                                    Color(.systemBackground))
//                        }
//                    }
//                    Rectangle()
//                        .fill(Color(.separator).opacity(0.25))
//                        .frame(height: 0.5)
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//            .overlay(
//                RoundedRectangle(cornerRadius: 8, style: .continuous)
//                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
//            )
//        }
//    }
//}

import SwiftUI

struct TablesBlock: View {
    // Optional preloaded data
    private let venRowsProp: [[String]]?
    private let empRowsProp: [[String]]?

    // Human-friendly headers
    var ventHeaders: [String] = ["Número de Ventanilla", "Tiempo en Servicio", "Tiempo de Espera"]
    var empHeaders:  [String] = ["Empleado", "Tiempo en Servicio", "Tiempo de Espera"]

    // UI state
    @State private var venRowsState: [[String]] = []
    @State private var empRowsState: [[String]] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Init

    init() {
        self.venRowsProp = nil
        self.empRowsProp = nil
    }

    init(
        venRows: [[String]],
        empRows: [[String]],
        ventHeaders: [String] = ["Número de Ventanilla", "Tiempo en Servicio", "Tiempo de Espera"],
        empHeaders:  [String] = ["Empleado", "Tiempo en Servicio", "Tiempo de Espera"]
    ) {
        self.venRowsProp = venRows
        self.empRowsProp = empRows
        self.ventHeaders = ventHeaders
        self.empHeaders = empHeaders
    }

    private var venRowsEffective: [[String]] { venRowsProp ?? venRowsState }
    private var empRowsEffective: [[String]] { empRowsProp ?? empRowsState }
    private var shouldFetch: Bool { venRowsProp == nil && empRowsProp == nil }

    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let msg = errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Group {
                Text("Promedios por ventanilla")
                    .font(.headline)
                    .foregroundStyle(.primary)
                SpreadsheetTable(headers: ventHeaders, rows: venRowsEffective)

                Text("Promedios por empleado")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.top, 10)
                SpreadsheetTable(headers: empHeaders, rows: empRowsEffective)
                    .frame(maxWidth: 620, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
        )
        .redacted(reason: isLoading ? .placeholder : [])
        .task {
            guard shouldFetch else { return }
            await fetchFromAPI()
        }
    }

    // MARK: - Networking
    private func fetchFromAPI() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let ventanillas = fetchVentAvgTimes()
            async let empleados   = fetchEmpAvgTimes()

            let v = try await ventanillas
            let e = try await empleados

            venRowsState = v.map {
                [String($0.id),
                 String(format: "%.2f", $0.avgServiceMinutes),
                 String(format: "%.2f", $0.avgWaitMinutes)]
            }

            empRowsState = e.map {
                [$0.empleadoNombre,
                 String(format: "%.2f", $0.avgServiceMinutes),
                 String(format: "%.2f", $0.avgWaitMinutes)]
            }

        } catch {
            errorMessage = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
        }
    }
}

// MARK: - Refined Table View
private struct SpreadsheetTable: View {
    let headers: [String]
    let rows: [[String]]

    // Proportional column sizing
    private var cols: [GridItem] {
        [
            GridItem(.flexible(minimum: 230, maximum: 320)), // Employee name
            GridItem(.flexible(minimum: 100, maximum: 120)), // AvgService
            GridItem(.flexible(minimum: 100, maximum: 120))  // AvgWait
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(headers, id: \.self) { h in
                    Text(h)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.72, blue: 0.83),
                                    Color(red: 0.63, green: 0.77, blue: 0.86)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Body rows
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    LazyVGrid(columns: cols, spacing: 0) {
                        ForEach(row.indices, id: \.self) { i in
                            Text(row[i])
                                .font(.footnote.monospacedDigit())
                                .foregroundColor(Color(.label))
                                .frame(maxWidth: .infinity,
                                       alignment: i == 0 ? .leading : .trailing)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(index.isMultiple(of: 2)
                                            ? Color(.systemGray6)
                                            : Color(.systemBackground))
                        }
                    }
                    Divider()
                        .background(Color(.separator).opacity(0.2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
            )
        }
    }
}
