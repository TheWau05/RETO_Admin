//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI

struct AbrirCerrarVentanillaPadView: View {
    let api: AdminAPI

    // Estado de la pantalla
    @State private var ventanilla = 1
    @State private var cerrada = true
    @State private var empleados: [EmployeeBasic] = []
    @State private var empleadoSel: EmployeeBasic? = nil
    @State private var asignados: [Int: EmployeeBasic] = [:] // empleado por ventanilla
    @State private var estados: [Int: Bool] = [:]            // cerrada/abierta por ventanilla
    @State private var loading = false
    @State private var sending = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                GeometryReader { geo in
                    let cardWidth = min(geo.size.width - 48, 980)

                    ScrollView {
                        VStack(alignment: .leading, spacing: AdminTheme.spacing) {

                            // Header
                            PageHeader(title: headerTitulo) {
                                Image(systemName: cerrada ? "lock.fill" : "lock.open.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(AdminColors.acento)
                            }

                            // Ventanilla + Toggle
                            encabezado(cardWidth: cardWidth)

                            // Dropdown de empleados
                            empleadoDropdown(cardWidth: cardWidth)

                            // Botón principal
                            PrimaryButton(
                                title: sending ? "Procesando..." : (cerrada ? "Abrir ventanilla" : "Cerrar ventanilla")
                            ) { Task { await onPrimaryButtonTap() } }
                            .disabled(sending) // no lo bloqueamos por empleado nulo

                            if let e = errorText {
                                Text(e).foregroundStyle(.red).padding(.top, 6)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navBarStyleGray()
            .tint(AdminColors.marca)
            .task { await loadEmployees() } // carga al entrar
            .onAppear {
                syncEstadoConSeleccion()
                syncEmpleadoConVentanilla()
            }
        }
    }

    // MARK: - Títulos

    private var headerTitulo: String {
        let emp = empleadoSel?.name ?? "Sin empleado"
        return "Ventanilla \(ventanilla) · \(emp)"
    }

    // MARK: - Carga de empleados

    private func loadEmployees() async {
        loading = true
        errorText = nil
        do {
            let xs = try await api.unassignedEmployees()
            await MainActor.run {
                empleados = xs.isEmpty ? fallbackEmployees() : xs
                if empleadoSel == nil { empleadoSel = empleados.first }
                syncEmpleadoConVentanilla()
                loading = false
                if xs.isEmpty { errorText = "No se pudo cargar empleados del servidor. Usando lista local." }
            }
        } catch {
            await MainActor.run {
                empleados = fallbackEmployees()
                if empleadoSel == nil { empleadoSel = empleados.first }
                loading = false
                errorText = "Error al cargar empleados: \(error.localizedDescription). Usando lista local."
            }
        }
    }

    private func fallbackEmployees() -> [EmployeeBasic] {
        [
            .init(id: 1, name: "Ana López"),
            .init(id: 2, name: "Bruno Díaz"),
            .init(id: 3, name: "Carla Ruiz"),
            .init(id: 4, name: "Diego Pérez"),
            .init(id: 5, name: "Eva García")
        ]
    }

    // MARK: - Estado por ventanilla (UI)

    private func estadoDe(vent: Int) -> Bool { estados[vent] ?? true }
    private func setEstado(vent: Int, cerrada: Bool) { estados[vent] = cerrada }
    private func guardarEstadoActual() { setEstado(vent: ventanilla, cerrada: cerrada) }
    private func syncEstadoConSeleccion() { cerrada = estadoDe(vent: ventanilla) }

    private func syncEmpleadoConVentanilla() {
        if let e = asignados[ventanilla] {
            empleadoSel = e
        } else if empleadoSel == nil {
            empleadoSel = empleados.first
        }
    }
    private func guardarEmpleadoActual() {
        if let e = empleadoSel { asignados[ventanilla] = e }
    }

    // MARK: - Acción principal

    private func onPrimaryButtonTap() async {
        // usa un empId seguro si por algo sigue nulo
        let empId = empleadoSel?.id ?? 1

        let newClosed = !cerrada
        let previous = cerrada
        cerrada = newClosed
        sending = true
        errorText = nil
        do {
            try await enviarCambioApi(newClosed, empId: empId)
            guardarEstadoActual()
            guardarEmpleadoActual()
        } catch {
            cerrada = previous
            errorText = "No se pudo procesar: \(error.localizedDescription)"
        }
        sending = false
    }

    private func enviarCambioApi(_ closed: Bool, empId: Int) async throws {
        if closed {
            try await api.closeVentanilla(ventanillaId: ventanilla)
        } else {
            try await api.openVentanilla(ventanillaId: ventanilla, empId: empId)
        }
    }

    // MARK: - Subvistas

    private func encabezado(cardWidth: CGFloat) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 22) {
                VentanillaMenu(value: $ventanilla) {
                    syncEstadoConSeleccion()
                    syncEmpleadoConVentanilla()
                }
                Toggle(isOn: Binding(
                    get: { cerrada },
                    set: { v in
                        cerrada = v
                        guardarEstadoActual()
                    })
                ) {
                    Text(cerrada ? "Cerrada" : "Abierta")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black)
                }
                .toggleStyle(.switch)
                .tint(AdminColors.marca)
                .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: cardWidth, alignment: .leading)
    }

    private func empleadoDropdown(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Asignar empleado")

            if loading && empleados.isEmpty {
                // Indicador mientras llega la lista
                HStack {
                    ProgressView()
                    Text("Cargando empleados…").foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25), lineWidth: 1))
            } else {
                Menu {
                    ForEach(empleados) { e in
                        Button {
                            empleadoSel = e
                            guardarEmpleadoActual()
                        } label: {
                            HStack {
                                Text(e.name)
                                Spacer()
                                if e.id == empleadoSel?.id { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(empleadoSel?.name ?? "Selecciona empleado")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                }
                .disabled(empleados.isEmpty)
            }
        }
        .frame(maxWidth: cardWidth, alignment: .leading)
    }
}
