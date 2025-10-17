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

            NavigationLink {
                StatusOverviewView(
                    ventanillas: allVentanillas,
                    estados: estados,
                    asignados: asignados
                )
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Ver estatus y asignaciones")
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AdminColors.marca.opacity(0.12))
                .foregroundStyle(AdminColors.marca)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
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

struct StatusOverviewView: View {
    let ventanillas: [Int]
    let estados: [Int: Bool]
    let asignados: [Int: EmployeeBasic]

    @State private var filtroVentanilla: Int? = nil
    @State private var filtroEmpleadoId: Int? = nil
    @State private var filtroEstado: EstadoFiltro = .todas
    @State private var query: String = ""
    @State private var sortKey: SortKey = .ventanilla
    @State private var ascending: Bool = true

    enum EstadoFiltro: String, CaseIterable, Identifiable {
        case todas = "Todas"
        case abiertas = "Abiertas"
        case cerradas = "Cerradas"
        var id: String { rawValue }
    }

    enum SortKey: String, CaseIterable, Identifiable {
        case ventanilla = "Ventanilla"
        case nombre = "Nombre"
        case estado = "Estado"
        var id: String { rawValue }
    }

    private var empleadosUnicos: [EmployeeBasic] {
        let xs = asignados.values
        let map = Dictionary(grouping: xs, by: { $0.id }).compactMap { $0.value.first }
        return map.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var listaFiltrada: [Int] {
        let filtrada = ventanillas
            .filter { v in
                if let f = filtroVentanilla, v != f { return false }
                if let empId = filtroEmpleadoId {
                    let asign = asignados[v]?.id
                    if asign != empId { return false }
                }
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

        let ordenada: [Int] = filtrada.sorted { a, b in
            switch sortKey {
            case .ventanilla:
                return ascending ? a < b : a > b
            case .nombre:
                let na = asignados[a]?.name ?? ""
                let nb = asignados[b]?.name ?? ""
                if na.caseInsensitiveCompare(nb) == .orderedSame {
                    return ascending ? a < b : a > b
                }
                return ascending
                    ? na.localizedCaseInsensitiveCompare(nb) == .orderedAscending
                    : na.localizedCaseInsensitiveCompare(nb) == .orderedDescending
            case .estado:
                let ea = estados[a] ?? true
                let eb = estados[b] ?? true
                if ea == eb {
                    return ascending ? a < b : a > b
                }
                return ascending ? (eb && !ea) : (!eb && ea)
            }
        }
        return ordenada
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                filtros
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
                            HStack(spacing: 8) {
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
            }
            .navigationTitle("Estatus de ventanillas")
        }
    }

    private var filtros: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Menu {
                    Button("Todas") { filtroVentanilla = nil }
                    if ventanillas.isEmpty == false {
                        ForEach(ventanillas.sorted(), id: \.self) { v in
                            Button("Ventanilla \(v)") { filtroVentanilla = v }
                        }
                    }
                } label: {
                    chip(texto: filtroVentanilla == nil ? "Ventanillas: Todas" : "Ventanilla \(filtroVentanilla!)")
                }

                Menu {
                    Button("Todos") { filtroEmpleadoId = nil }
                    ForEach(empleadosUnicos) { e in
                        Button(e.name) { filtroEmpleadoId = e.id }
                    }
                } label: {
                    if let id = filtroEmpleadoId,
                       let emp = empleadosUnicos.first(where: { $0.id == id }) {
                        chip(texto: "Empleado: \(emp.name)")
                    } else {
                        chip(texto: "Empleados: Todos")
                    }
                }
            }

            Picker("Estado", selection: $filtroEstado) {
                ForEach(EstadoFiltro.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Picker("Ordenar por", selection: $sortKey) {
                    ForEach(SortKey.allCases) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    ascending.toggle()
                } label: {
                    Label(ascending ? "Ascendente" : "Descendente",
                          systemImage: ascending ? "arrow.up.arrow.down.circle" : "arrow.down.arrow.up.circle")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Buscar por nombre o ventanilla", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if query.isEmpty == false {
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

            HStack {
                Button {
                    resetFiltros()
                } label: {
                    Label("Reiniciar filtros", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal)
    }

    private func chip(texto: String) -> some View {
        HStack(spacing: 8) {
            Text(texto)
                .font(.callout.weight(.semibold))
            Image(systemName: "chevron.down")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }

    private func resetFiltros() {
        filtroVentanilla = nil
        filtroEmpleadoId = nil
        filtroEstado = .todas
        query = ""
        sortKey = .ventanilla
        ascending = true
    }
}
