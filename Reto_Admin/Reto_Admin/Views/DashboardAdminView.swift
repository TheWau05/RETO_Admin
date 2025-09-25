//
//  DashboardAdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI

struct DashboardAdminView: View {
    @EnvironmentObject var router: AdminRouter

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Modo Administrador")
                        .font(.largeTitle.bold())
                        .foregroundColor(AdminColors.text)
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(AdminColors.acento)
                }
                .padding(.top, 8)

                Button {
                    router.switchTo(.abrirCerrar)
                } label: {
                    AdminActionCard(
                        title: "Abrir Cerrar ventanillas",
                        systemImage: "rectangle.portrait.on.rectangle.portrait",
                        color: AdminColors.marca
                    )
                }

                Button {
                    router.switchTo(.historial)
                } label: {
                    AdminActionCard(
                        title: "Historial de ventanilla",
                        systemImage: "clock.arrow.circlepath",
                        color: AdminColors.marca
                    )
                }

                Button {
                    router.switchTo(.estadistica)
                } label: {
                    AdminActionCard(
                        title: "Estadística de ventana",
                        systemImage: "chart.bar.fill",
                        color: AdminColors.marca
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
