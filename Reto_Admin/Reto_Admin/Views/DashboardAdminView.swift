//
//  DashboardAdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI

struct DashboardAdminView: View {
    @EnvironmentObject var store: CitasStore
    @StateObject private var vm = AvgTimesViewModel()

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
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

                    NavigationLink { AbrirCerrarVentanillaPadView() } label: {
                        AdminActionCard(
                            title: "Abrir/Cerrar ventanillas",
                            systemImage: "rectangle.portrait.on.rectangle.portrait",
                            color: .marca
                        )
                    }

                    NavigationLink { HistorialAdminView() } label: {
                        AdminActionCard(
                            title: "Historial de ventanilla",
                            systemImage: "clock.arrow.circlepath",
                            color: .marca
                        )
                    }

                    NavigationLink { EstadisticaVentanillaView() } label: {
                        AdminActionCard(
                            title: "Estadística de ventana",
                            systemImage: "chart.bar.fill",
                            color: .marca
                        )
                    }


                    if let msg = vm.errorMessage {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }


                    HStack {
                        Spacer()
                        TablesBlock(
                            venRows: vm.ventRows.map {
                                [String($0.id),
                                 String(format: "%.2f", $0.avgService),
                                 String(format: "%.2f", $0.avgWait)]
                            },
                            empRows: vm.empRows.map {
                                [String($0.id),
                                 String(format: "%.2f", $0.avgService),
                                 String(format: "%.2f", $0.avgWait)]
                            }
                        )
                        .redacted(reason:
                            (vm.ventRows.isEmpty && vm.empRows.isEmpty && vm.errorMessage == nil)
                            ? .placeholder : []
                        )
                        Spacer()
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { vm.fetch() }
        .refreshable { vm.fetch() }
    }
}

#Preview {
    NavigationStack {
        DashboardAdminView()
            .environmentObject(CitasStore())
    }
}
