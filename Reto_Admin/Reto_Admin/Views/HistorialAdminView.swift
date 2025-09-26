//
//  HistorialAdminView.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//
//
//  HistorialAdminView.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//
import SwiftUI

struct HistorialAdminView: View {
    @State private var historial: [HistorialUs] = []
    @State private var isLoading = false
    
    @State private var ventanillaSeleccionada = 1
    @State private var fechaSeleccionada = Date()
    
    private let opcionesVentanilla = [1, 2, 3, 4]
    
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
                
                // Card de Filtros
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filtros").font(.headline)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ventanilla").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Ventanilla", selection: $ventanillaSeleccionada) {
                            ForEach(opcionesVentanilla, id: \.self) { n in
                                Text("Ventanilla \(n)").tag(n)
                            }
                        }
                        .pickerStyle(.segmented)
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
                
                // Card de Resultados
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
    }
    
    func cargarDatos() async {
        isLoading = true
        do {
            historial = try await fetchHistorial(fecha: fechaSeleccionada, ventanillaId: ventanillaSeleccionada)
        } catch {
            print("Error al cargar historial: \(error)")
            historial = []
        }
        isLoading = false
    }
}

#if DEBUG
struct HistorialAdminView_Previews: PreviewProvider {
    static var previews: some View {
        HistorialAdminView()
    }
}
#endif
