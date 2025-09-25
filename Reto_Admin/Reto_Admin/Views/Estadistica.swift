import SwiftUI
import Charts

struct EstadisticaVentanillaView: View {
    @State private var averages: [TurnoAverageHour] = []
    @State private var comparison: [TurnosComparisonItem] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeader(title: "Estadística (demo)") {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AdminColors.acento)
                }

                HStack(spacing: 12) {
                    StatCard(title: "Turnos Próximos",
                             value: comparison.filter { $0.period == "Future" }.map(\.turnosCount).reduce(0,+),
                             color: .green)
                    StatCard(title: "Ventanillas Abiertas",
                             value: 12, color: .orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tiempo de espera y duración por hora").font(.headline)
                    Chart {
                        ForEach(averages) { row in
                            BarMark(x: .value("Hora", row.hourStart, unit: .hour),
                                    y: .value("Min", row.avgServiceMinutes)).foregroundStyle(.blue)
                            BarMark(x: .value("Hora", row.hourStart, unit: .hour),
                                    y: .value("Min", row.avgWaitMinutes)).foregroundStyle(.orange)
                        }
                    }.frame(height: 220)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Turnos 24h pasado y futuro").font(.headline)
                    Chart {
                        ForEach(comparison) { item in
                            LineMark(x: .value("Hora", item.hourStart, unit: .hour),
                                     y: .value("Turnos", item.turnosCount))
                            .foregroundStyle(item.period == "Past" ? .gray : .green)
                        }
                    }.frame(height: 220)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navBarStyleGray()
        .tint(AdminColors.marca)
        .onAppear { loadDemo() }
    }

    private func loadDemo() {
        let now = Date()
        averages = (0..<24).map { i in
            TurnoAverageHour(hourStart: Calendar.current.date(byAdding: .hour, value: i, to: now)!,
                             avgServiceMinutes: Double.random(in: 8...15),
                             avgWaitMinutes: Double.random(in: 8...15))
        }
        let past = (0..<24).map { i in
            TurnosComparisonItem(period: "Past",
                                 hourStart: Calendar.current.date(byAdding: .hour, value: -i, to: now)!,
                                 turnosCount: Int.random(in: 0...12))
        }
        let future = (1...24).map { i in
            TurnosComparisonItem(period: "Future",
                                 hourStart: Calendar.current.date(byAdding: .hour, value: i, to: now)!,
                                 turnosCount: Int.random(in: 0...12))
        }
        comparison = past + future
    }
}
