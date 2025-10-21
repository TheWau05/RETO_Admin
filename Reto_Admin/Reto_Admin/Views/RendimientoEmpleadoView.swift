//
//  RendimientoEmpleadoView.swift
//  Reto_Admin
//
//  Created by Oliver on 17/10/25.
//

import SwiftUI

struct RendimientoEmpleadoView: View {
    
    @State private var empleadoSeleccionado: Int?
    @State private var fechaInicio = Date()
    @State private var fechaFin = Date()
    
    @State private var empleados: [Empleado] = []
    @State private var reporte: PerformanceReport?
    @State private var isLoading = false
    @State private var hasSearched = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Reporte de Desempeño") {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)
                }
                .padding(.horizontal, 20)
                
                filtrosCard
                
                if isLoading {
                    ProgressView("Generando reporte...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 50)
                } else if let reporte = reporte {
                    resultadosView(reporte: reporte)
                } else {
                    estadoVacio
                }
                
                Spacer()
            }
        }
        .navBarStyleGray()
        .tint(AdminColors.marca)
        .task {
            await cargarEmpleados()
        }
    }
        
    private var filtrosCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Filtros de Búsqueda").font(.headline)
            
            Picker("Empleado", selection: $empleadoSeleccionado) {
                Text("Seleccionar un empleado").tag(Int?.none)
                ForEach(empleados) { empleado in
                    Text(empleado.fullName).tag(empleado.Id as Int?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5)))

            
            HStack {
                DatePicker("Desde", selection: $fechaInicio, displayedComponents: .date)
                DatePicker("Hasta", selection: $fechaFin, displayedComponents: .date)
            }
            
            Button(action: {
                Task {
                    await generarReporte()
                }
            }) {
                Text("Generar Reporte")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(empleadoSeleccionado == nil ? Color.gray : AdminColors.marca)
                    .cornerRadius(12)
            }
            .disabled(empleadoSeleccionado == nil)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func resultadosView(reporte: PerformanceReport) -> some View {
        // Resumen de KPIs
        HStack(spacing: 16) {
            kpiCard(titulo: "Turnos Atendidos", valor: "\(reporte.summary.TotalTurnosAtendidos)", icono: "person.2.fill")
            kpiCard(titulo: "Tiempo Promedio", valor: "\(reporte.summary.TiempoPromedioPorTurno) min", icono: "stopwatch.fill")
        }
        .padding(.horizontal, 20)
        
        List {
//            Section(header: Text("Historial de Servicio Detallado").font(.headline)) {
//                if reporte.details.isEmpty {
//                    Text("No hay turnos atendidos para este empleado en el periodo seleccionado.")
//                } else {
////                    ForEach(reporte.details) { detalle in
////                        turnoRow(detalle: detalle)
////                    }
//                    ForEach(reporte.details.filter { $0.End_Time != nil }) { detalle in
//                        turnoRow(detalle: detalle)
//                    }
//                }
//            }
            Section(header: Text("Historial de Servicio Detallado").font(.headline)) {
                let turnosCompletados = reporte.details.filter { $0.End_Time != nil }
                
                if turnosCompletados.isEmpty {
                    Text("No hay turnos completados para este empleado en el periodo seleccionado.")
                } else {
                    ForEach(turnosCompletados) { detalle in
                        turnoRow(detalle: detalle)
                    }
                }
            }

        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private var estadoVacio: some View {
        VStack(spacing: 10) {
            Image(systemName: hasSearched ? "tray" : "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            
            Text(hasSearched ? "No se encontraron resultados." : "Selecciona un empleado y un rango de fechas para generar un reporte.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
    
    private func kpiCard(titulo: String, valor: String, icono: String) -> some View {
        HStack {
            Image(systemName: icono)
                .font(.title)
                .foregroundStyle(AdminColors.marca)
            VStack(alignment: .leading) {
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(valor)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func turnoRow(detalle: PerformanceDetail) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Turno \(detalle.TurnoId)")
                    .fontWeight(.bold)
                Text(formattedDate(from: detalle.Start_Time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(detalle.Duracion_Minutos ?? 0) min")
                    .fontWeight(.semibold)
                    .foregroundStyle(AdminColors.acento)
                Text("Ventanilla \(detalle.Ventanilla_Id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    
    func generarReporte() async {
        guard let empleadoId = empleadoSeleccionado else { return }
        
        isLoading = true
        hasSearched = true
        reporte = nil
        
        do {
            self.reporte = try await fetchPerformanceReport(
                employeeId: empleadoId,
                startDate: fechaInicio,
                endDate: fechaFin
            )
        } catch {
            print("Error al generar el reporte: \(error)")
        }
        
        isLoading = false
    }
    
    func cargarEmpleados() async {
        do {
            self.empleados = try await fetchAllEmployees()
        } catch {
            print("Error al cargar empleados: \(error)")
        }
    }

}



#if DEBUG
struct RendimientoEmpleadoView_Previews: PreviewProvider {
    static var previews: some View {
        RendimientoEmpleadoView()
    }
}
#endif
