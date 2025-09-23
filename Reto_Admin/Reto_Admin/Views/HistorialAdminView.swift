//
//  HistorialAdminView.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//

import SwiftUI

struct HistorialAdminView: View {
    
    @State private var historialCompleto: [HistorialAdmin] = historialDeVentanilla
    @State private var historialFiltrado: [HistorialAdmin] = []
    
    @State private var ventanillaSeleccionada = 1
    @State private var fechaSeleccionada = Date()
    
    private let opcionesVentanilla = [1, 2, 3, 4]

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    Text("Selecciona una Ventanilla")
                        .font(.headline)
                    
                    Picker("Ventanilla", selection: $ventanillaSeleccionada) {
                        ForEach(opcionesVentanilla, id: \.self) { numVentanilla in
                            Text("Ventanilla \(numVentanilla)").tag(numVentanilla)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Filtrar por fecha:")
                        
                        DatePicker(
                            "Selecciona una fecha",
                            selection: $fechaSeleccionada,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    .padding(.top, 10)

                }
                .padding()
                
                    Table(historialFiltrado) {
                    TableColumn("ID Receta", value: \.idReceta)
                    TableColumn("Hora de Atención") { historialItem in
                        Text(historialItem.horaAtencion, style: .time)
                    }
                    .width(150)
                }
            }
            .navigationTitle("Historial por Ventanilla")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: ventanillaSeleccionada) { _ in
                filtrarHistorial()
            }
            .onChange(of: fechaSeleccionada) { _ in
                filtrarHistorial()
            }
            .onAppear {
                filtrarHistorial()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func filtrarHistorial() {
        let filtradoPorVentanilla = historialCompleto.filter { item in
            item.ventanillaID == ventanillaSeleccionada
        }
        
        historialFiltrado = filtradoPorVentanilla.filter { item in
            Calendar.current.isDate(item.horaAtencion, inSameDayAs: fechaSeleccionada)
        }
    }
}

#Preview {
    HistorialAdminView()
}
