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
                    Text("Selecciona una Ventanilla").font(.headline)

                    Picker("Ventanilla", selection: $ventanillaSeleccionada) {
                        ForEach(opcionesVentanilla, id: \.self) { n in
                            Text("Ventanilla \(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Filtrar por fecha:")
                        DatePicker("", selection: $fechaSeleccionada, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.top, 10)
                }
                .padding()

                Table(historialFiltrado) {
                    TableColumn("ID Receta", value: \.idReceta)
                    TableColumn("Hora de Atención") { item in
                        Text(item.horaAtencion, style: .time)
                    }
                    .width(150)
                }
            }
            .navigationTitle("Historial por Ventanilla")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: ventanillaSeleccionada) { _ in filtrarHistorial() }
            .onChange(of: fechaSeleccionada) { _ in filtrarHistorial() }
            .onAppear { filtrarHistorial() }
        }
        .navigationViewStyle(.stack)
    }

    private func filtrarHistorial() {
        let v = historialCompleto.filter { $0.ventanillaID == ventanillaSeleccionada }
        historialFiltrado = v.filter { Calendar.current.isDate($0.horaAtencion, inSameDayAs: fechaSeleccionada) }
    }
}

#Preview { HistorialAdminView() }
