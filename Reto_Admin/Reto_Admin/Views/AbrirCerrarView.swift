//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//
//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI

private let kACVDefaultsKey = "AbrirCerrarVentanilla_State_v2"

private struct EmployeeMini: Codable, Hashable {
    let id: Int
    let name: String
}

private struct ACVState: Codable {
    var asignados: [Int: EmployeeMini] = [:]
    var estados:   [Int: Bool] = [:]
    var ventanillaSeleccionada: Int = 1
}

private extension EmployeeMini {
    init(from basic: EmployeeBasic) { self.init(id: basic.id, name: basic.name) }
}
private extension EmployeeBasic {
    init(from mini: EmployeeMini) { self.init(id: mini.id, name: mini.name) }
}

struct AbrirCerrarVentanillaPadView: View {
    let api: AdminAPI

    @Binding var loggedIn: Bool
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

    @State private var showingEmergencySheet = false
    @State private var emergencyUsername = ""
    @State private var forcing = false
    @State private var emergencyResult: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                GeometryReader { geo in
                    VStack {
                        Spacer(minLength: 40)
                        contentCard(width: geo.size.width * 0.9, height: geo.size.height * 0.65)
                        Spacer(minLength: 60)
                        VStack(alignment: .trailing) {
                            BotonSalirSesion(loggedIn: $loggedIn)
                        }

                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .navigationTitle("Abrir / Cerrar Ventanilla")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AdminColors.marca)
            .task {
                loadPersistedState()
                syncEstadoConSeleccion()
                syncEmpleadoConVentanilla()
                await loadEmployees()
                if asignados.isEmpty && estados.isEmpty {
                    await bootstrapDesdeServidor()
                }
            }
                        

            .onChange(of: ventanilla) { _, _ in
                syncEstadoConSeleccion()
                syncEmpleadoConVentanilla()
                persistState()
            }
        }
    }

    private func contentCard(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 44) {
            headerSection
            empleadoSelector
            actionButton

            if let e = errorText {
                Text(e).foregroundStyle(.red).font(.callout)
            }

            if serviceDown {
                Button("Reintentar conexión") { Task { await loadEmployees() } }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }

            NavigationLink {
                StatusOverviewView(
                    ventanillas: allVentanillas,
                    estados: estados,
                    asignados: asignados
                )
            } label: {
                ZStack {
                    // Left icon (keeps its place)
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 16)

                    // Centered title (overlays in the middle)
                    Text("Ver estatus y asignaciones")
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(maxWidth: .infinity)          // no trailing alignment
                .padding(.vertical, 16)
                .background(AdminColors.marca.opacity(0.12))
                .foregroundStyle(AdminColors.marca)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
            .zIndex(0)

            Button {
                showingEmergencySheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Forzar turno")
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AdminColors.marca.opacity(0.08))
                .foregroundStyle(AdminColors.marca)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .zIndex(0)
            .sheet(isPresented: $showingEmergencySheet) {
                emergencyTurnoSheet
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
                        persistState()
                    }
                    .frame(maxWidth: 240)
                    .padding(.top, 6)
                    
                }

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: cerrada ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)

                    Text(empleadoSel?.name ?? "Sin empleado asignado")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.secondary)
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
                    .contentShape(Rectangle())
                }
                .disabled(serviceDown)
                .zIndex(2)
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
                .contentShape(Rectangle())
        }
        .disabled(sending || loading || serviceDown || empleadoSel == nil)
        .zIndex(2)
    }

    private var allVentanillas: [Int] {
        var s = Set<Int>()
        s.insert(ventanilla)
        s.formUnion(estados.keys)
        s.formUnion(asignados.keys)
        return Array(s).sorted()
    }

    private func loadEmployees() async {
        loading = true
        serviceDown = false
        errorText = nil
        do {
            let xs = try await api.unassignedEmployees()
            await MainActor.run {
                empleados = xs
                if empleadoSel == nil {
                    empleadoSel = asignados[ventanilla] ?? xs.first
                }
                loading = false
            }
        } catch {
            await MainActor.run {
                empleados = []
                loading = false
                serviceDown = true
                errorText = "Servicio no disponible. Verifica la red o intenta más tarde."
            }
        }
    }

    @MainActor
    private func bootstrapDesdeServidor() async {
        do {
            let server = try await fetchVentanillasStatus()
            var nuevosEstados: [Int: Bool] = [:]
            var nuevosAsignados: [Int: EmployeeBasic] = [:]
            for s in server {
                let estaCerrada = !s.disponible
                nuevosEstados[s.id] = estaCerrada
                if let emp = s.empId {
                    let nombre = asignados[s.id]?.name ?? "Empleado \(emp)"
                    nuevosAsignados[s.id] = EmployeeBasic(id: emp, name: nombre)
                }
            }
            estados = nuevosEstados
            asignados = nuevosAsignados
            if let e = nuevosAsignados[ventanilla] {
                empleadoSel = e
            } else if empleadoSel == nil {
                empleadoSel = empleados.first
            }
            cerrada = estadoDe(vent: ventanilla)
            persistState()
        } catch {
            if empleadoSel == nil { empleadoSel = empleados.first }
        }
    }

    private func estadoDe(vent: Int) -> Bool { estados[vent] ?? true }
    private func setEstado(vent: Int, cerrada: Bool) { estados[vent] = cerrada }
    private func guardarEstadoActual() { setEstado(vent: ventanilla, cerrada: cerrada); persistState() }
    private func syncEstadoConSeleccion() { cerrada = estadoDe(vent: ventanilla) }

    private func syncEmpleadoConVentanilla() {
        if let e = asignados[ventanilla] {
            empleadoSel = e
        } else if empleadoSel == nil && !empleados.isEmpty {
            empleadoSel = empleados.first
        }
    }

    private func guardarEmpleadoActual() {
        if let e = empleadoSel {
            asignados[ventanilla] = e
            persistState()
        }
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

    private func persistState() {
        var snapshot = ACVState(
            asignados: asignados.mapValues { EmployeeMini(from: $0) },
            estados: estados,
            ventanillaSeleccionada: ventanilla
        )
        snapshot.estados[ventanilla] = cerrada
        if let e = empleadoSel { snapshot.asignados[ventanilla] = EmployeeMini(from: e) }
        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: kACVDefaultsKey)
        } catch { }
    }

    private func loadPersistedState() {
        guard let data = UserDefaults.standard.data(forKey: kACVDefaultsKey) else { return }
        do {
            let snapshot = try JSONDecoder().decode(ACVState.self, from: data)
            estados    = snapshot.estados
            ventanilla = snapshot.ventanillaSeleccionada
            var asign: [Int: EmployeeBasic] = [:]
            for (k, v) in snapshot.asignados { asign[k] = EmployeeBasic(from: v) }
            asignados = asign
            cerrada = estadoDe(vent: ventanilla)
            empleadoSel = asignados[ventanilla] ?? empleadoSel
        } catch { }
    }

    private var emergencyTurnoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Forzar turno de emergencia")
                    .font(.system(size: 24, weight: .bold))

                TextField("Usuario", text: $emergencyUsername)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if forcing {
                    ProgressView("Creando turno...")
                        .frame(maxWidth: .infinity)
                } else {
                    Button {
                        Task { await forceEmergencyTurno() }
                    } label: {
                        Text("Crear turno de emergencia")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AdminColors.marca)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(emergencyUsername.isEmpty)
                }

                if let r = emergencyResult {
                    Text(r)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(30)
            .navigationTitle("Turno de emergencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showingEmergencySheet = false }
                }
            }
        }
    }

    private func forceEmergencyTurno() async {
        guard !emergencyUsername.isEmpty else { return }
        forcing = true
        emergencyResult = nil

        do {
            _ = try await api.createEmergencyTurno(username: emergencyUsername)
            await MainActor.run {
                emergencyResult = "✅ Turno de emergencia asignado exitosamente."
                forcing = false
            }
        } catch {
            await MainActor.run {
                emergencyResult = "❌ Error al crear el turno"
                forcing = false
            }
        }
    }
}
