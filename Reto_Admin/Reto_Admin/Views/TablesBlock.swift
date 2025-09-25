//
//  TablesBlock.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 25/09/25.
//

import SwiftUI

struct TablesBlock: View {
    let api: AdminAPI
    @StateObject private var vm: SpreadsheetsViewModel

    init(api: AdminAPI) {
        self.api = api
        _vm = StateObject(wrappedValue: SpreadsheetsViewModel(api: api))
    }

    var body: some View {
        VStack(spacing: 20) {
            SectionTitle(text: "Spreadsheets en vivo")

            if vm.loading {
                ProgressView().padding()
            } else if let err = vm.errorText {
                Text(err).foregroundStyle(Color.red)
            } else {
                responsiveTables
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
        .task { await vm.load() }
    }

    private var responsiveTables: some View {
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

    private var empleadosTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promedios por empleado").font(.headline)
            Table(vm.empleados) {
                TableColumn("Empleado") { Text("#\($0.empId)") }.width(80)
                TableColumn("Servicio min") { Text(intString($0.avgServiceMinutes)) }
                TableColumn("Espera min") { Text(intString($0.avgWaitMinutes)) }
            }
            .frame(minHeight: 180)
        }
    }

    private var ventanillasTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promedios por ventanilla").font(.headline)
            Table(vm.ventanillas) {
                TableColumn("Ventanilla") { Text("#\($0.ventanillaId)") }.width(100)
                TableColumn("Servicio min") { Text(intString($0.avgServiceMinutes)) }
                TableColumn("Espera min") { Text(intString($0.avgWaitMinutes)) }
            }
            .frame(minHeight: 180)
        }
    }
}

private func intString(_ d: Double) -> String { String(Int(d.rounded())) }
