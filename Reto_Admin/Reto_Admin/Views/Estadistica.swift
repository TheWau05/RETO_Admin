import SwiftUI
import Charts

struct EstadisticaVentanillaView: View {
    @StateObject private var vm: EstadisticaViewModel

    init(api: AdminAPI) {
        _vm = StateObject(wrappedValue: EstadisticaViewModel(api: api))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeader(title: "Estadística") {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)
                }

                if vm.loading {
                    ProgressView().padding()
                } else if let err = vm.errorText {
                    Text(err).foregroundStyle(Color.red)
                } else {
                    HStack(spacing: 12) {
                        StatCard(title: "Turnos Próximos",
                                 value: totalFuture(),
                                 color: Color.green)

                        StatCard(title: "Ventanillas Abiertas",
                                 value: 12,
                                 color: Color.orange)
                    }

                    HStack(spacing: 12) {
                        StatCard(title: "Duración servicio promedio",
                                 value: avg(vm.averages.map { $0.avgServiceMinutes }),
                                 color: Color.blue)

                        StatCard(title: "Espera promedio",
                                 value: avg(vm.averages.map { $0.avgWaitMinutes }),
                                 color: Color.black)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tiempo de espera y duración por hora")
                            .font(.headline)
                        Chart {
                            ForEach(vm.averages) { row in
                                BarMark(x: .value("Hora", row.hourStart, unit: .hour),
                                        y: .value("Min", row.avgServiceMinutes))
                                    .foregroundStyle(Color.blue)
                                BarMark(x: .value("Hora", row.hourStart, unit: .hour),
                                        y: .value("Min", row.avgWaitMinutes))
                                    .foregroundStyle(Color.orange)
                            }
                        }
                        .frame(height: 220)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Turnos 24h pasado y futuro")
                            .font(.headline)
                        Chart {
                            ForEach(vm.comparison) { item in
                                LineMark(x: .value("Hora", item.hourStart, unit: .hour),
                                         y: .value("Turnos", item.turnosCount))
                                .foregroundStyle(item.period == "Past" ? Color.gray : Color.green)
                            }
                        }
                        .frame(height: 220)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navBarStyleGray()
        .tint(AdminColors.marca)
        .task { await vm.load() }
    }

    private func totalFuture() -> Int {
        vm.comparison
            .filter { $0.period == "Future" }
            .reduce(0) { $0 + $1.turnosCount }
    }

    private func avg(_ xs: [Double]) -> Int {
        guard !xs.isEmpty else { return 0 }
        return Int(xs.reduce(0, +) / Double(xs.count))
    }
}
