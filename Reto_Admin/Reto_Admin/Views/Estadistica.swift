import SwiftUI
import Charts

struct EstadisticaVentanillaView: View {
    @EnvironmentObject var store: CitasStore
    
    private var currentDate: Date {
        Date()
    }
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private var orderedHours: [Int] {
        let now = Calendar.current.component(.hour, from: Date())
        return (0..<24).map { (now + $0) % 24 }
    }

    struct BarDatum: Identifiable {
        let id = UUID(); let label: String; let value: Int
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Resumen (basado en citas)
                HStack(spacing: 12) {
                    StatCard(title: "Turnos Proximos",
                             value: 15,
                             color: .green)
                    
                    StatCard(title: "Ventanillas Abiertas",
                             value: 12,
                             color: .orange)
                }
                
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        StatCard(title: "duracion servicio por promedio",
                                 value: 12,
                                 color: .blue)
                        
                        StatCard(title: "Duracion espara promedio",
                                 value: 12,
                                 color: .black)
                    }
                }
            }
            .padding()
            
            // --- Remaining Charts ---
            Text("Tiempo de Espera y Duración de Turno (past)")
            Chart {
                ForEach(orderedHours, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", String(hour)),
                        y: .value("Value", Double.random(in: 0...10))
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: orderedHours.map { String($0) })
            }
            .frame(height: 200)
            .padding()
            
            Text("Turnos 24h past and future")
            Chart {
                ForEach(orderedHours, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", String(hour)),
                        y: .value("Value", Double.random(in: 0...10))
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: orderedHours.map { String($0) })
            }
            .frame(height: 200)
            .padding()
        }
        .navigationTitle("Estadística")
    }
}


struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(value)").font(.title.bold())
            ProgressView(value: value > 0 ? 1.0 : 0.0) // decorativo
                .tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack { EstadisticaVentanillaView() }
        .environmentObject(CitasStore())
}
