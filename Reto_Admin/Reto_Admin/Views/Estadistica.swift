//
//  AdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI
import Charts

struct EstadisticaVentanillaView: View {
    @EnvironmentObject var store: CitasStore

    struct BarDatum: Identifiable { let id = UUID(); let label: String; let value: Int }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Resumen (basado en citas)
                HStack(spacing: 12) {
                    StatCard(title: "Total de citas",
                             value: store.totalCitas,
                             color: .green)

                    StatCard(title: "Máx. por ventanilla",
                             value: store.maxPorVentanilla,
                             color: .orange)
                }

                // Gráfico (citas por ventanilla)
                let data = store.items.map { BarDatum(label: $0.nombre, value: $0.citas) }

                GroupBox("Estado actual") {
                    Chart(data) { d in
                        BarMark(
                            x: .value("Ventanilla", d.label),
                            y: .value("Citas", d.value)
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 220)
                }
            }
            .padding()
        }
        .navigationTitle("Estadística")
    }
}

// Tarjeta simple reutilizable
struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(value)").font(.title.bold())
            ProgressView(value: value > 0 ? 1.0 : 0.0) // decorativo
                .tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack { EstadisticaVentanillaView() }
        .environmentObject(CitasStore())
}
