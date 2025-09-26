import SwiftUI
import Charts

extension Array where Element == Double {
    var averageRounded: Double {
        guard !isEmpty else { return 0 }
        return (reduce(0, +) / Double(count)).rounded()
    }
}

// MARK: - Vista principal
struct EstadisticaVentanillaView: View {
    @State private var turnos: [Turnos24ComparisonItem] = []
    @State private var turnosAvg: [Turno24AverageHour] = []
    @State private var ventanillasAvailable: [VentanillaStatus] = []
    
    
    @EnvironmentObject var store: CitasStore   // Para render en canvas
    
    // Total de turnos futuros (ahead)
    private var upcomingTurnosCount: Int {
        turnos.filter { $0.period.lowercased() == "future" }
              .map(\.turnosCount)
              .reduce(0, +)
    }
    
    // Ventanillas abiertas
    private var ventanillasAvailableCount: Int {
        ventanillasAvailable.filter { $0.disponible }.count
    }
    
    // Tiempo peomedio por atención en ventanilla
    private var avgService: Double {
        turnosAvg.compactMap { $0.avgServiceMinutes }.averageRounded
    }
    
    // Tiempo promedio por espera a ventanilla
    private var avgWait: Double {
        turnosAvg.compactMap { $0.avgWaitMinutes }.averageRounded
    }
    
    // Helper for Turnos Count graph
    private var binnedTurnos: [TurnosComparisonBin] {
        turnos.map { item in
            let hour = Calendar.current.component(.hour, from: item.hourStart)
            return TurnosComparisonBin(hour: hour,
                                       period: item.period,
                                       count: item.turnosCount)
        }
    }
    
    // Helper for Service and Wait Times Graph
    private var binnedAverages: [TurnosAverageBin] {
        turnosAvg.flatMap { item in
            let hour = Calendar.current.component(.hour, from: item.hourStart)
            return [
                TurnosAverageBin(hour: hour, type: "Espera", value: item.avgWaitMinutes ?? 0),
                TurnosAverageBin(hour: hour, type: "Servicio", value: item.avgServiceMinutes ?? 0)
            ]
        }
    }
    
    private var currentHour: Int { Calendar.current.component(.hour, from: Date()) }
    private var orderedHours: [Int] {
        (0..<12).map { (currentHour + $0) % 24 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Tarjetas superiores
                HStack(spacing: 12) {
                    StatCard(title: "Turnos Próximos",
                             value: upcomingTurnosCount,
                             color: .green)
                    
                    StatCard(title: "Ventanillas Abiertas",
                             value: ventanillasAvailableCount,
                             color: .orange)
                }
                
                HStack(spacing: 12) {
                    StatCard(title: "Duración servicio promedio",
                             value: Int(avgService),
                             color: .blue)
                    
                    StatCard(title: "Duración espera promedio",
                             value: Int(avgWait),
                             color: .black)
                }
            }
            .padding()
            
            // Turnos Count Graph
            VStack(alignment: .leading, spacing: 8) {
                Text("Turnos por Hora (Pasado vs Futuro)")
                    .font(.title2)
                    .bold()
                    .padding(.leading)

                Chart(binnedTurnos) { item in
                    BarMark(
                        x: .value("Hora del Día", item.hour),
                        y: .value("Turnos", item.count)
                    )
                    .foregroundStyle(by: .value("Periodo", item.period))
                    .position(by: .value("Periodo", item.period))
                }
                .chartXAxisLabel("Hora del Día", position: .bottom, alignment: .center)
                .chartYAxisLabel("Turnos por Hora", position: .leading, alignment: .center)
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: Array(0...23)) { value in
                        if let intVal = value.as(Int.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(intVal)")
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        if let intVal = value.as(Int.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(intVal) Turnos")
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                }
                .chartLegend(.visible)
                .frame(height: 300)
            }
            
            // Service and Wait Times Graph
            VStack(alignment: .leading, spacing: 8) {
                Text("Duración Promedio de Espera vs Servicio")
                    .font(.title2)
                    .bold()
                    .padding(.leading)

                Chart(binnedAverages) { item in
                    BarMark(
                        x: .value("Hora del Día", item.hour),
                        y: .value("Minutos", item.value)
                    )
                    .foregroundStyle(by: .value("Tipo", item.type))
                    .position(by: .value("Tipo", item.type))
                }
                .chartXAxisLabel("Hora del Día", position: .bottom, alignment: .center)
                .chartYAxisLabel("Minutos Promedio", position: .leading, alignment: .center)
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: Array(0...23)) { value in
                        if let intVal = value.as(Int.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(intVal)")
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        if let intVal = value.as(Int.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(intVal) Min")
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                }
                .chartLegend(.visible)
                .frame(height: 300)
                
            }
        }
        .navigationTitle("Estadística")
        .task {
            do {
                turnos = try await fetchTurnos24ComparisonItem()
                turnosAvg = try await fetchTurno24AverageHour()
                ventanillasAvailable = try await fetchVentanillasStatus()
                
            
                print("Ventanillas cargadas:", ventanillasAvailable.count)
                print("Turnos loaded:", turnos.count)
                print("Avgs SERVICED & WAITTIME", turnosAvg)
                print("Turnos PAST & FUTURE:", turnos)
            } catch {
                print("Error fetching data:", error)
            }
        }

    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EstadisticaVentanillaView()
            .environmentObject(CitasStore()) // Para render en canvas
    }
}

