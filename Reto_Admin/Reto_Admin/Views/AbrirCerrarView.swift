//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI

struct AbrirCerrarVentanillaPadView: View {
    @State private var ventanilla = 1
    @State private var cerrada = true
    @State private var horaSeleccionada: String? = nil
    @State private var estados: [Int: [String: Bool]] = [:]

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
                        PrimaryButton(title: cerrada ? "Abrir ventanilla" : "Cerrar ventanilla") {
                            cerrada.toggle()
                            guardarEstadoActual()
                        }
                        .padding(.top, 4)
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
                .foregroundStyle(.black)

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
                        .foregroundStyle(.black)
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
            SectionTitle(text: "Escoge hora de apertura")
                .padding(.horizontal, 6)

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

    // Persistencia en memoria para estado por ventanilla y hora
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
}

#Preview {
    AbrirCerrarVentanillaPadView()
}
