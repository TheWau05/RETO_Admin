//
//  AbrirCerrarView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI

// MARK: - Color de marca
extension Color {
    static let ColorBoton = Color(red: 0.003, green: 0.319, blue: 0.431)
    // O si tienes un color en Assets:
    // static let ColorBoton = Color("ColorBoton")
}

// MARK: - Vista Principal
struct AbrirCerrarVentanillaPadView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ventanilla = 0
    @State private var cerrada = true
    @State private var horaSeleccionada: String? = nil
    
    // Horas generadas
    private let horas: [String] = {
        var r: [String] = []
        for h in 6...19 {
            r.append(String(format: "%02d:00", h))
            r.append(String(format: "%02d:30", h))
        }
        return r
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                GeometryReader { geo in
                    contenido(ancho: geo.size.width)
                }
            }
            .navigationTitle("Abrir Cerrar Ventanas")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.ColorBoton)
        }
    }
    
    // MARK: - Contenido principal
    @ViewBuilder
    private func contenido(ancho: CGFloat) -> some View {
        let columnas = columnasPara(ancho: ancho)
        let cardWidth = min(ancho - 48, 980)
        
        VStack(spacing: 28) {
            tarjeta(cardWidth: cardWidth, columnas: columnas)
            barraInferior(cardWidth: cardWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func columnasPara(ancho: CGFloat) -> [GridItem] {
        let count = ancho > 1000 ? 6 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
    
    // MARK: - Tarjeta central
    @ViewBuilder
    private func tarjeta(cardWidth: CGFloat, columnas: [GridItem]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.85), Color.gray.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            
            VStack(spacing: 22) {
                Text("Ventanilla")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                HStack(spacing: 24) {
                    Stepper(value: $ventanilla, in: 0...99) {
                        Text("\(ventanilla)")
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    .tint(.white)
                    
                    Toggle(isOn: $cerrada) {
                        Text(cerrada ? "Cerrada" : "Abierta")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .toggleStyle(.switch)
                    .tint(.ColorBoton)
                    .frame(maxWidth: 360)
                }
                .padding(.horizontal, 32)
                
                Text("Escoge hora de apertura")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                
                HorasGrid(horas: horas, horaSeleccionada: $horaSeleccionada, columnas: columnas)
                    .frame(height: cardWidth > 900 ? 360 : 300)
                
                Button {
                    cerrada.toggle()
                } label: {
                    Text(cerrada ? "Abrir ventanilla" : "Cerrar ventanilla")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(maxWidth: 520)
                        .padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.ColorBoton))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                }
            }
            .padding(28)
        }
        .frame(width: cardWidth)
    }
    
    // MARK: - Barra inferior
    @ViewBuilder
    private func barraInferior(cardWidth: CGFloat) -> some View {
        HStack(spacing: 28) {
            Button { dismiss() } label: {
                Text("Salir")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(maxWidth: 320)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.ColorBoton))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
            
            Button { aceptarAccion() } label: {
                Text("Aceptar")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(maxWidth: 320)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.ColorBoton))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
        }
        .frame(width: cardWidth)
    }
    
    private func aceptarAccion() {
        // Aquí guardas o envías lo que el usuario seleccionó
        print("Ventanilla: \(ventanilla), Hora: \(horaSeleccionada ?? ""), Estado: \(cerrada ? "Cerrada" : "Abierta")")
    }
}

// MARK: - Subvista para grid de horas
struct HorasGrid: View {
    let horas: [String]
    @Binding var horaSeleccionada: String?
    let columnas: [GridItem]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columnas, spacing: 16) {
                ForEach(horas, id: \.self) { h in
                    Button {
                        horaSeleccionada = h
                    } label: {
                        Text(h)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(horaSeleccionada == h ? Color.ColorBoton : Color.white)
                            )
                            .foregroundStyle(horaSeleccionada == h ? Color.white : Color.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(horaSeleccionada == h ? .clear : Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.14))
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview
#Preview {
    AbrirCerrarVentanillaPadView()
}
