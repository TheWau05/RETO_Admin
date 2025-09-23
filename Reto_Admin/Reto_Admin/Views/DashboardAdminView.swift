//
//  DashboardAdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI

struct DashboardAdminView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Modo Administrador")
                        .font(.largeTitle.bold())
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.acento)
                }
                .padding(.top, 8)

                AdminActionCard(
                    titulo: "Abrir/Cerrar ventanillas",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    color: .marca
                )

                AdminActionCard(
                    titulo: "Historial de ventanilla",
                    systemImage: "clock.arrow.circlepath",
                    color: .marca
                )

                AdminActionCard(
                    titulo: "Estadística de ventana",
                    systemImage: "chart.bar.fill",
                    color: .marca
                )

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminActionCard: View {
    let titulo: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.85))
                    .frame(width: 48, height: 48)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(titulo)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(RoundedRectangle(cornerRadius: 20).fill(color))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
    DashboardAdminView()
    }
}
