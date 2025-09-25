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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    PageHeader(title: "Modo Administrador") {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(AdminColors.acento)
                    }

                    Button { router.switchTo(.abrirCerrar) } label: {
                        AdminActionCard(title: "Abrir Cerrar ventanillas",
                                        systemImage: "rectangle.portrait.on.rectangle.portrait",
                                        color: AdminColors.marca)
                    }
                    Button { router.switchTo(.historial) } label: {
                        AdminActionCard(title: "Historial de ventanilla",
                                        systemImage: "clock.arrow.circlepath",
                                        color: AdminColors.marca)
                    }
                    Button { router.switchTo(.estadistica) } label: {
                        AdminActionCard(title: "Estadística de ventana",
                                        systemImage: "chart.bar.fill",
                                        color: AdminColors.marca)
                    }

                    HStack {
                        Spacer()
                        // Visual-only (sin API)
                        TablesBlock()
                            .frame(maxWidth: 980)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DashboardAdminView()
        .environmentObject(AdminRouter())
}
