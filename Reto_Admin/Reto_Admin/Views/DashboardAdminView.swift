//
//  DashboardAdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI

// MARK: - Models
struct ResumenGeneral: Codable, Identifiable {
    var id: String { "resumen" }
    let TotalAtendidos: Int
    let PromedioServicio: Double
    let PromedioEspera: Double
    let VentanillasActivas: Int
}

struct VentanillaRow: Codable, Identifiable {
    var id: Int { Ventanilla_Id }
    let Ventanilla_Id: Int
    let TotalAtendidos: Int
    let PromedioServicio: Double?
    let PromedioEspera: Double?
    let EmpleadoAsignado: String?
}

struct InsightsGemini: Codable {
    let incidencias: [String]
    let picos_demanda: [String]
    let rendimiento_destacado: [String]
    let recomendaciones: [String]
}

// MARK: - Service
final class ReporteService {
    // Cambia a tu backend:
    private let base = URL(string: "http://127.0.0.1:8000")!
    private var resumenURL: URL { base.appendingPathComponent("/api/reporte/resumen") }
    private var ventanillasURL: URL { base.appendingPathComponent("/api/reporte/ventanillas") }
    private var insightsURL: URL { base.appendingPathComponent("/api/reporte/insights") }

    func fetchResumen() async throws -> ResumenGeneral {
        try await get(resumenURL)
    }
    func fetchVentanillas() async throws -> [VentanillaRow] {
        try await get(ventanillasURL)
    }
    func fetchInsights() async throws -> InsightsGemini {
        try await get(insightsURL)
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - ViewModel
@MainActor
final class PromptVM: ObservableObject {
    enum Reveal: Equatable {
        case none, resumen, ventanillas, insights, todo
    }

    @Published var prompt: String = ""
    @Published var reveal: Reveal = .none

    @Published var isLoading = false
    @Published var error: String?

    @Published var resumen: ResumenGeneral?
    @Published var ventanillas: [VentanillaRow] = []
    @Published var insights: InsightsGemini?

    private let service = ReporteService()

    func submit() {
        let normalized = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "resumen": reveal = .resumen
        case "ventanillas": reveal = .ventanillas
        case "insights": reveal = .insights
        case "todo": reveal = .todo
        default:
            reveal = .none
            error = "Prompt no reconocido. Prueba: resumen, ventanillas, insights o todo."
            return
        }
        Task { await loadIfNeeded() }
    }

    private func shouldLoadResumen() -> Bool { resumen == nil && (reveal == .resumen || reveal == .todo) }
    private func shouldLoadVentanillas() -> Bool { ventanillas.isEmpty && (reveal == .ventanillas || reveal == .todo) }
    private func shouldLoadInsights() -> Bool { insights == nil && (reveal == .insights || reveal == .todo) }

    private func clearErrors() { error = nil }

    func loadIfNeeded() async {
        clearErrors()
        isLoading = true
        defer { isLoading = false }

        do {
            async let r: ResumenGeneral? = shouldLoadResumen() ? service.fetchResumen() : resumen
            async let v: [VentanillaRow]? = shouldLoadVentanillas() ? service.fetchVentanillas() : ventanillas
            async let i: InsightsGemini? = shouldLoadInsights() ? service.fetchInsights() : insights

            let (sr, sv, si) = try await (r, v, i)
            if let sr { resumen = sr }
            if let sv { ventanillas = sv }
            if let si { insights = si }
        } catch {
            self.error = "No se pudieron cargar datos: \(error.localizedDescription)"
        }
    }
}

// MARK: - Views
struct DashboardAdminView: View {
    @StateObject private var vm = PromptVM()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                // Centered Search Bar
                HStack {
                    TextField("Escribe un prompt (resumen, ventanillas, insights, todo)", text: $vm.prompt, onCommit: vm.submit)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
                        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 4)

                    Button {
                        vm.submit()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title3.weight(.semibold))
                            .padding(12)
                            .background(Circle().fill(Color.accentColor.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Buscar")
                }
                .padding(.horizontal, 24)

                if let error = vm.error, vm.reveal == .none {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Content revealed by prompt
                Group {
                    switch vm.reveal {
                    case .none:
                        HintCard()
                    case .resumen:
                        if let r = vm.resumen { CardResumen(resumen: r) }
                    case .ventanillas:
                        if !vm.ventanillas.isEmpty { CardVentanillas(ventanillas: vm.ventanillas) }
                    case .insights:
                        if let i = vm.insights { CardInsights(insights: i) }
                    case .todo:
                        VStack(spacing: 14) {
                            if let r = vm.resumen { CardResumen(resumen: r) }
                            if !vm.ventanillas.isEmpty { CardVentanillas(ventanillas: vm.ventanillas) }
                            if let i = vm.insights { CardInsights(insights: i) }
                        }
                    }
                }
                .padding(.horizontal, 20)

                if vm.isLoading {
                    ProgressView("Cargando…").padding(.top, 6)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Subviews
private struct HintCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("👀 Este panel solo muestra datos cuando ingresas un prompt válido.")
                .font(.headline)
            Text("Prueba con:")
            VStack(alignment: .leading, spacing: 4) {
                Text("• resumen — métricas generales (24h)")
                Text("• ventanillas — desglose por ventanilla")
                Text("• insights — observaciones de Gemini")
                Text("• todo — muestra todo lo anterior")
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

private struct CardResumen: View {
    let resumen: ResumenGeneral
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen (24h)").font(.title3).bold()
            HStack(spacing: 10) {
                StatPill(title: "Atendidos", value: "\(resumen.TotalAtendidos)")
                StatPill(title: "Serv. prom.", value: String(format: "%.1f min", resumen.PromedioServicio))
                StatPill(title: "Espera prom.", value: String(format: "%.1f min", resumen.PromedioEspera))
                StatPill(title: "Ventanillas", value: "\(resumen.VentanillasActivas)")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

private struct CardVentanillas: View {
    let ventanillas: [VentanillaRow]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ventanillas").font(.title3).bold()
            ForEach(ventanillas.sorted { $0.Ventanilla_Id < $1.Ventanilla_Id }) { v in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Ventanilla \(v.Ventanilla_Id)").font(.headline)
                        if let emp = v.EmpleadoAsignado, !emp.isEmpty {
                            Text(emp).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Atendidos: \(v.TotalAtendidos)").font(.subheadline)
                        Text("Serv. prom.: \(format(v.PromedioServicio))").font(.subheadline)
                        Text("Espera prom.: \(format(v.PromedioEspera))").font(.subheadline)
                    }
                }
                Divider()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
    private func format(_ val: Double?) -> String {
        guard let v = val else { return "—" }
        return String(format: "%.1f min", v)
    }
}

private struct CardInsights: View {
    let insights: InsightsGemini
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights (Gemini)").font(.title3).bold()
            if !insights.incidencias.isEmpty { Bullet("Incidencias", items: insights.incidencias) }
            if !insights.picos_demanda.isEmpty { Bullet("Picos de demanda", items: insights.picos_demanda) }
            if !insights.rendimiento_destacado.isEmpty { Bullet("Rendimiento destacado", items: insights.rendimiento_destacado) }
            if !insights.recomendaciones.isEmpty { Bullet("Recomendaciones", items: insights.recomendaciones) }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
    private func Bullet(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(items.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(items[i])
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Entry
struct DashboardAdminView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardAdminView()
    }
}
