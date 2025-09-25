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
    @State private var horaSeleccionada: String? = nil
    @State private var estados: [Int: [String: Bool]] = [:]
    @State private var sending = false
    @State private var errorText: String?

    private let horas: [String] = {
        var r: [String] = []
        for h in 6...19 { r.append(String(format: "%02d:00", h)); r.append(String(format: "%02d:30", h)) }
        return r
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                GeometryReader { geo in
                    let cols = columnasPara(ancho: geo.size.width)
                    let cardWidth = min(geo.size.width - 48, 980)

                    VStack(spacing: AdminTheme.spacing) {
                        encabezado
                        selectorHoras(cardWidth: cardWidth, columnas: cols)

                        PrimaryButton(
                            title: sending ? "Procesando..." : (cerrada ? "Abrir ventanilla" : "Cerrar ventanilla")
                        ) {
                            Task { await onPrimaryButtonTap() }
                        }
                        .disabled(horaSeleccionada == nil || sending)

                        if let e = errorText {
                            Text(e).foregroundStyle(Color.red)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Abrir Cerrar Ventanas")
            .navigationBarTitleDisplayMode(.inline)
            .navBarStyleGray()
            .tint(AdminColors.marca)
        }
    }

    private var encabezado: some View {
        VStack(spacing: 14) {
            Text("Ventanilla")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.black)

            HStack(spacing: 22) {
                VentanillaMenu(value: $ventanilla) { syncEstadoConSeleccion() }

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
    }

    @ViewBuilder
    private func selectorHoras(cardWidth: CGFloat, columnas: [GridItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(text: "Escoge hora de apertura").padding(.horizontal, 6)
            HourGrid(hours: horas, selected: $horaSeleccionada, columns: columnas) { _ in
                syncEstadoConSeleccion()
            }
            .frame(height: cardWidth > 900 ? 360 : 300)
            .background(RoundedRectangle(cornerRadius: AdminTheme.corner).fill(AdminColors.panel))
        }
    }

    private func columnasPara(ancho: CGFloat) -> [GridItem] {
        let count = ancho > 1000 ? 6 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    private func estadoDe(vent: Int, hora: String) -> Bool {
        estados[vent]?[hora] ?? true
    }

    private func setEstado(vent: Int, hora: String, cerrada: Bool) {
        var mapa = estados[vent] ?? [:]
        mapa[hora] = cerrada
        estados[vent] = mapa
    }

    private func guardarEstadoActual() {
        guard let h = horaSeleccionada else { return }
        setEstado(vent: ventanilla, hora: h, cerrada: cerrada)
    }

    private func syncEstadoConSeleccion() {
        guard let h = horaSeleccionada else { return }
        cerrada = estadoDe(vent: ventanilla, hora: h)
    }

    // MARK: - Actions
    private func onPrimaryButtonTap() async {
        guard let _ = horaSeleccionada else {
            errorText = "Selecciona una hora primero."
            return
        }

        // 1) Optimistic UI: alternamos el estado local inmediatamente
        let newClosed = !cerrada
        let previous = cerrada
        cerrada = newClosed
        sending = true
        errorText = nil

        do {
            try await enviarEstado(newClosed)
            guardarEstadoActual() // persistimos en el diccionario local
        } catch {
            // 2) Revertimos si falla
            cerrada = previous
            errorText = "No se pudo enviar. Intenta de nuevo."
        }

        sending = false
    }

    /// Envía al API el estado indicado (true = cerrada, false = abierta)
    private func enviarEstado(_ closed: Bool) async throws {
        guard let h = horaSeleccionada else { return }
        let comps = h.split(separator: ":")
        let hour = Int(comps[0]) ?? 0
        let minute = Int(comps[1]) ?? 0
        var base = Calendar.current.startOfDay(for: Date())
        base = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? Date()
        try await api.setVentanillaState(ventanillaId: ventanilla, hourStart: base, closed: closed)
    }
}
