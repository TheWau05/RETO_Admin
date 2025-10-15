//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI

struct AbrirCerrarVentanillaPadView: View {
    let api: AdminAPI

    @State private var ventanilla = 1
    @State private var cerrada = true
    @State private var empleados: [EmployeeBasic] = []
    @State private var empleadoSel: EmployeeBasic?
    @State private var asignados: [Int: EmployeeBasic] = [:]
    @State private var estados: [Int: Bool] = [:]
    @State private var loading = false
    @State private var sending = false
    @State private var serviceDown = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                GeometryReader { geo in
                    VStack {
                        Spacer(minLength: 40)
                        contentCard(width: geo.size.width * 0.9, height: geo.size.height * 0.65)
                        Spacer(minLength: 60)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .navigationTitle("Abrir / Cerrar Ventanilla")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AdminColors.marca)
            .task { await loadEmployees() }
            .onAppear {
                syncEstadoConSeleccion()
                syncEmpleadoConVentanilla()
            }
        }
    }

    private func contentCard(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 44) {
            headerSection
            empleadoSelector
            actionButton
            if let e = errorText {
                Text(e)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
            if serviceDown {
                Button("Reintentar conexión") { Task { await loadEmployees() } }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(50)
        .frame(maxWidth: width, minHeight: height)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ventanilla")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.primary)

                    VentanillaMenu(value: $ventanilla) {
                        syncEstadoConSeleccion()
                        syncEmpleadoConVentanilla()
                    }
                    .frame(maxWidth: 240)
                    .padding(.top, 6)
                }

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: cerrada ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)

                    if let emp = empleadoSel {
                        Text(emp.name)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Sin empleado asignado")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var empleadoSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asignar empleado")
                .font(.system(size: 22, weight: .semibold))

            if loading && empleados.isEmpty {
                HStack {
                    ProgressView()
                    Text("Cargando empleados…").foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
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
                        Text(empleadoSel?.name ?? (serviceDown ? "Servicio no disponible" : "Selecciona empleado"))
                            .foregroundStyle(.primary)
                            .font(.system(size: 22))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                }
                .disabled(empleados.isEmpty || serviceDown)
            }
        }
    }

    private var actionButton: some View {
        Button {
            Task { await onPrimaryButtonTap() }
        } label: {
            Text(sending ? "Procesando..." : (cerrada ? "Abrir ventanilla" : "Cerrar ventanilla"))
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(AdminColors.marca)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(sending || loading || serviceDown || empleadoSel == nil)
    }

    // MARK: - Lógica

    private func loadEmployees() async {
        loading = true
        serviceDown = false
        errorText = nil
        do {
            let xs = try await api.unassignedEmployees()
            await MainActor.run {
                empleados = xs
                empleadoSel = asignados[ventanilla] ?? xs.first
                loading = false
            }
        } catch {
            await MainActor.run {
                empleados = []
                empleadoSel = nil
                loading = false
                serviceDown = true
                errorText = "Servicio no disponible. Verifica la red o intenta más tarde."
            }
        }
    }

    private func estadoDe(vent: Int) -> Bool { estados[vent] ?? true }
    private func setEstado(vent: Int, cerrada: Bool) { estados[vent] = cerrada }
    private func guardarEstadoActual() { setEstado(vent: ventanilla, cerrada: cerrada) }
    private func syncEstadoConSeleccion() { cerrada = estadoDe(vent: ventanilla) }

    private func syncEmpleadoConVentanilla() {
        if let e = asignados[ventanilla] {
            empleadoSel = e
        } else if empleadoSel == nil && !empleados.isEmpty {
            empleadoSel = empleados.first
        }
    }
    private func guardarEmpleadoActual() {
        if let e = empleadoSel { asignados[ventanilla] = e }
    }

    private func onPrimaryButtonTap() async {
        if serviceDown { return }
        guard let empId = empleadoSel?.id else { return }

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
            errorText = "No se pudo procesar el cambio."
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
}
