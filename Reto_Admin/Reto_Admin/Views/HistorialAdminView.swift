//
//  HistorialAdminView.swift
//  Reto_Admin
//
//  Created by Alumno on 22/09/25.
//
import SwiftUI

struct HistorialAdminView: View {
    // reemplazarla cuando conectemos API
    @State private var historialCompleto: [HistorialAdmin] = historialDeVentanilla

    @State private var ventanillaSeleccionada = 1
    @State private var fechaSeleccionada = Date()
    @State private var search = ""

    private let opcionesVentanilla = [1, 2, 3, 4]

    // Derivados
    private var historialFiltrado: [HistorialAdmin] {
        historialCompleto
            .filter { $0.ventanillaID == ventanillaSeleccionada }
            .filter { Calendar.current.isDate($0.horaAtencion, inSameDayAs: fechaSeleccionada) }
            .filter { search.isEmpty ? true : $0.idReceta.localizedCaseInsensitiveContains(search) }
            .sorted { $0.horaAtencion > $1.horaAtencion }
    }

    private var resumen: (total: Int, primera: Date?, ultima: Date?) {
        let arr = historialFiltrado.sorted { $0.horaAtencion < $1.horaAtencion }
        return (arr.count, arr.first?.horaAtencion, arr.last?.horaAtencion)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header consistente
                    PageHeader(title: "Historial de ventanilla") {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AdminColors.acento)
                    }

                    filtrosCard

                    HStack(spacing: 12) {
                        StatCard(title: "Registros", value: resumen.total, color: .marca)
                        StatCard(title: "Primero", value: resumen.primera == nil ? 0 : 1, color: .orange)
                        StatCard(title: "Último", value: resumen.ultima == nil ? 0 : 1, color: .blue)
                    }

                    resultadosCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navBarStyleGray()
        .tint(AdminColors.marca)
    }

    // Subvistas

    private var filtrosCard: some View {
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

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fecha").font(.subheadline).foregroundStyle(.secondary)
                    DatePicker("", selection: $fechaSeleccionada, displayedComponents: .date)
                        .labelsHidden()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Buscar ID Receta").font(.subheadline).foregroundStyle(.secondary)
                    TextField("Ej. REC-98765", text: $search)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .onChange(of: ventanillaSeleccionada, initial: false) { _, _ in /* derivado calcula solo */ }
        .onChange(of: fechaSeleccionada, initial: false) { _, _ in /* derivado calcula solo */ }
        .onChange(of: search, initial: false) { _, _ in /* derivado calcula solo */ }
    }

    private var resultadosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados").font(.headline)

            if historialFiltrado.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("No hay registros para los filtros seleccionados.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Table(historialFiltrado) {
                    TableColumn("ID Receta", value: \.idReceta)
                    TableColumn("Hora de Atención") { item in
                        Text(item.horaAtencion, style: .time)
                    }
                    .width(160)
                }
                .frame(minHeight: 220)
                .background(.clear)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

