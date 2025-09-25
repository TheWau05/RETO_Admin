//
//  SpreadsheetsViewModel.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 25/09/25.
//

import Foundation

@MainActor
final class SpreadsheetsViewModel: ObservableObject {
    @Published var empleados: [EmployeeAvg] = []
    @Published var ventanillas: [VentanillaAvg] = []
    @Published var loading = false
    @Published var errorText: String?

    private let api: AdminAPI
    init(api: AdminAPI) { self.api = api }

    func load() async {
        loading = true
        errorText = nil
        do {
            async let a = api.avgTimesByEmployee()
            async let b = api.avgTimesByVentanilla()
            empleados = try await a
            ventanillas = try await b
        } catch {
            errorText = "No se pudo cargar"
        }
        loading = false
    }
}

