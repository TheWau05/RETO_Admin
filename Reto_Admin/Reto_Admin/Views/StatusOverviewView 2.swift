//
//  StatusOverviewView 2.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 18/10/25.
//
import SwiftUI

struct StatusOverviewView: View {
    let ventanillas: [Int]
    let estados: [Int: Bool]
    let asignados: [Int: EmployeeBasic]

    @State private var filtroEstado: EstadoFiltro = .todas
    @State private var query: String = ""

    enum EstadoFiltro: String, CaseIterable, Identifiable {
        case todas = "Todas"
        case abiertas = "Abiertas"
        case cerradas = "Cerradas"
        var id: String { rawValue }
    }

    private var listaFiltrada: [Int] {
        ventanillas
            .filter { v in
                switch filtroEstado {
                case .todas: break
                case .abiertas:
                    if (estados[v] ?? true) == true { return false }
                case .cerradas:
                    if (estados[v] ?? true) == false { return false }
                }
                if query.isEmpty { return true }
                let nombre = asignados[v]?.name ?? "Sin empleado asignado"
                let texto = "Ventanilla \(v) \(nombre)"
                return texto.localizedCaseInsensitiveContains(query)
            }
            .sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Selector de estado simple
                Picker("Estado", selection: $filtroEstado) {
                    ForEach(EstadoFiltro.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Buscador
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Buscar por nombre o ventanilla", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)

                // Botón reiniciar filtros
                Button {
                    filtroEstado = .todas
                    query = ""
                } label: {
                    Label("Reiniciar filtros", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                // Lista principal
                List {
                    ForEach(listaFiltrada, id: \.self) { v in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ventanilla \(v)")
                                    .font(.headline)
                                Text(asignados[v]?.name ?? "Sin empleado asignado")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            let cerrada = estados[v] ?? true
                            HStack(spacing: 6) {
                                Image(systemName: cerrada ? "lock.fill" : "lock.open.fill")
                                    .foregroundStyle(cerrada ? .red : .green)
                                Text(cerrada ? "Cerrada" : "Abierta")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(cerrada ? .red : .green)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Estatus de ventanillas")
        }
    }
}
