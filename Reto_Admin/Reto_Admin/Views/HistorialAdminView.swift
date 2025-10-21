//
//  HistorialAdminView.swift
//  Reto_Admin
//
//  Created by Oliver on 22/09/25.
//

import SwiftUI

struct HistorialAdminView: View {
    @State private var historial: [HistorialUs] = []
    @State private var isLoading = false
    
    @State private var fechaSeleccionada = Date()
    
    @State private var ventanillas: [NumVentanilla] = []
    @State private var ventanillaSeleccionada: Int?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Historial de ventanilla") {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filtros").font(.headline)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ventanilla").font(.subheadline).foregroundStyle(.secondary)
                        
                        Picker("Seleccionar ventanilla", selection: $ventanillaSeleccionada) {
                            Text("Seleccionar ventanilla").tag(Int?.none)
                            ForEach(ventanillas) { v in
                                Text("Ventanilla \(v.Id)").tag(v.Id as Int?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5)))
                    }

                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fecha").font(.subheadline).foregroundStyle(.secondary)
                        DatePicker("", selection: $fechaSeleccionada, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                .padding(.horizontal, 20)
                .onChange(of: ventanillaSeleccionada) { _, _ in Task { await cargarDatos() } }
                .onChange(of: fechaSeleccionada) { _, _ in Task { await cargarDatos() } }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resultados (\(historial.count))").font(.headline)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if historial.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(.secondary)
                            Text("No hay registros para los filtros seleccionados.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        Table(historial.sorted(by: { $0.endTime > $1.endTime })) {
                            TableColumn("Receta", value: \.perscriptionId)
                            TableColumn("Paciente", value: \.pacienteName)
                            TableColumn("Hora Final") { item in
                                Text(item.endTime, style: .time)
                            }
                            .width(120)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navBarStyleGray()
        .tint(AdminColors.marca)
        .task {
            await cargarDatos()
        }
        .task {
            await cargarVentanillas()
        }

    }
    
    func cargarDatos() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let ventId = ventanillaSeleccionada else {
            historial = []
            return
        }
        
        do {
            historial = try await fetchHistorial(fecha: fechaSeleccionada, ventanillaId: ventId)
        } catch {
            print("Error al cargar historial: \(error)")
            historial = []
        }
    }

    
    func cargarVentanillas() async {
        do {
            ventanillas = try await fetchAllVentanillas()
            
            if ventanillaSeleccionada == nil, let primera = ventanillas.first {
                ventanillaSeleccionada = primera.Id
            }
            
            if let ventId = ventanillaSeleccionada {
                historial = try await fetchHistorial(fecha: fechaSeleccionada, ventanillaId: ventId)
            }
        } catch {
            print("Error al cargar ventanillas: \(error)")
        }
    }

}

#if DEBUG
struct HistorialAdminView_Previews: PreviewProvider {
    static var previews: some View {
        HistorialAdminView()
    }
}
#endif
