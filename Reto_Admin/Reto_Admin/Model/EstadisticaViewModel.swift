//
//  EstadisticaViewModel.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

@MainActor
final class EstadisticaViewModel: ObservableObject {
    @Published var averages: [TurnoAverageHour] = []
    @Published var comparison: [TurnosComparisonItem] = []
    @Published var loading = false
    @Published var errorText: String?

    private let api: AdminAPI
    init(api: AdminAPI) { self.api = api }

    func load() async {
        loading = true
        errorText = nil
        do {
            async let a = api.turnos24hAverages()
            async let c = api.turnos24hComparison()
            averages = try await a
            comparison = try await c
            averages.sort { $0.hourStart < $1.hourStart }
            comparison.sort { $0.hourStart < $1.hourStart }
        } catch {
            errorText = "No se pudo cargar"
        }
        loading = false
    }
}
