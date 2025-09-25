//
//  TablesBlock.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 25/09/25.
//

import SwiftUI

// Filas “fake” solo para demo visual
struct EmpRow: Identifiable {
    let id: Int
    let serviceMin: Int
    let waitMin: Int
}

struct VentRow: Identifiable {
    let id: Int
    let serviceMin: Int
    let waitMin: Int
}

struct TablesBlock: View {
    // Datos de demo (random)
    private let empRows: [EmpRow] = (1...6).map {
        EmpRow(id: $0, serviceMin: Int.random(in: 8...15), waitMin: Int.random(in: 8...15))
    }
    private let ventRows: [VentRow] = (1...4).map {
        VentRow(id: $0, serviceMin: Int.random(in: 8...15), waitMin: Int.random(in: 8...15))
    }

    var body: some View {
        VStack(spacing: 20) {
            SectionTitle(text: "Spreadsheets (demo visual)")

            GeometryReader { geo in
                let twoCols = geo.size.width > 900
                Group {
                    if twoCols {
                        HStack(alignment: .top, spacing: 20) {
                            empleadosTable.frame(maxWidth: .infinity)
                            ventanillasTable.frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 20) {
                            empleadosTable
                            ventanillasTable
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 340)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
    }

    private var empleadosTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promedios por empleado").font(.headline)

            Table(empRows) {
                TableColumn("Empleado") { row in
                    Text("#\(row.id)")
                }
                .width(100)

                TableColumn("Servicio min") { row in
                    Text("\(row.serviceMin)")
                }

                TableColumn("Espera min") { row in
                    Text("\(row.waitMin)")
                }
            }
            .frame(minHeight: 180)
        }
    }

    private var ventanillasTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promedios por ventanilla").font(.headline)

            Table(ventRows) {
                TableColumn("Ventanilla") { row in
                    Text("#\(row.id)")
                }
                .width(120)

                TableColumn("Servicio min") { row in
                    Text("\(row.serviceMin)")
                }

                TableColumn("Espera min") { row in
                    Text("\(row.waitMin)")
                }
            }
            .frame(minHeight: 180)
        }
    }
}
