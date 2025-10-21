//
//  DashboardAdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.


//DashboardAdminView

import SwiftUI

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

struct ExecResponse: Decodable {
    let resumen: ResumenGeneral?
    let ventanillas: [VentanillaRow]?
    let insights: InsightsGemini?
}

private struct AskGeminiEnvelope: Decodable {
    let prompt: String?
    let response: String?
}

struct GeminiFlexible: Codable {
    let rawText: String?
    let insights: InsightsGemini?
}

final class ReporteService {
    private let base = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!
    private var execURL: URL { base.appendingPathComponent("/reports/executive-summary") }
    private var askURL: URL { base.appendingPathComponent("/ask/gemini") }

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 45
        cfg.timeoutIntervalForResource = 90
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: cfg)
    }()

    func fetchExecutive() async throws -> ExecResponse {
        var req = URLRequest(url: execURL)
        req.httpMethod = "GET"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("close", forHTTPHeaderField: "Connection")
        let data = try await dataWithRetry(for: req)
        return try parseExecutive(data: data)
    }

    
    func askGemini(prompt: String) async throws -> GeminiFlexible {
        var req = URLRequest(url: askURL)
        req.httpMethod = "POST"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("close", forHTTPHeaderField: "Connection")

        let body: [String: Any] = ["prompt": prompt, "ask": prompt]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await dataWithRetry(for: req)

        if let env = try? JSONDecoder().decode(AskGeminiEnvelope.self, from: data),
           let resp = env.response {
            let unescaped = resp
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\/", with: "/")

            if let d = unescaped.data(using: .utf8) {

                if let ins = try? JSONDecoder().decode(InsightsGemini.self, from: d) {
                    return GeminiFlexible(rawText: nil, insights: ins)
                }

                if let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    if let direct = obj["direct_answer"] as? String, !direct.isEmpty {
                        return GeminiFlexible(rawText: direct, insights: nil)
                    }
                    if let answer = obj["answer"] as? String, !answer.isEmpty {
                        return GeminiFlexible(rawText: answer, insights: nil)
                    }
                    if let msg = obj["message"] as? String, !msg.isEmpty {
                        return GeminiFlexible(rawText: msg, insights: nil)
                    }
                }
            }

            let plain = unescaped.trimmingCharacters(in: .whitespacesAndNewlines)
            if !plain.isEmpty { return GeminiFlexible(rawText: plain, insights: nil) }
        }

        if let ins = try? JSONDecoder().decode(InsightsGemini.self, from: data) {
            return GeminiFlexible(rawText: nil, insights: ins)
        }

        if let s = String(data: data, encoding: .utf8) {
            return GeminiFlexible(rawText: s.trimmingCharacters(in: .whitespacesAndNewlines), insights: nil)
        }

        throw URLError(.cannotParseResponse)
    }

    private func dataWithRetry(for req: URLRequest, retries: Int = 2) async throws -> Data {
        var last: Error?
        for attempt in 0...retries {
            do {
                let (data, resp) = try await session.data(for: req)
                if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    throw NSError(domain: "HTTP", code: http.statusCode, userInfo: ["body": body])
                }
                return data
            } catch {
                last = error
                let ns = error as NSError
                let transient = [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost]
                if attempt < retries && (transient.contains(ns.code) || ns.localizedDescription.localizedCaseInsensitiveContains("reset")) {
                    try await Task.sleep(nanoseconds: UInt64(300_000_000 * (attempt + 1)))
                    continue
                }
            }
        }
        throw last ?? URLError(.unknown)
    }

    private func parseExecutive(data: Data) throws -> ExecResponse {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            var r: ResumenGeneral?
            var v: [VentanillaRow]?
            var i: InsightsGemini?
            if let rr = obj["resumen"] as? [String: Any] { r = try? decodeDict(ResumenGeneral.self, rr) }
            if let vv = obj["ventanillas"] as? [[String: Any]] { v = try? decodeArray([VentanillaRow].self, vv) }
            if let ii = obj["insights"] as? [String: Any] { i = try? decodeDict(InsightsGemini.self, ii) }
            if let dataNode = obj["data"] as? [String: Any] {
                if r == nil, let rr = dataNode["resumen"] as? [String: Any] { r = try? decodeDict(ResumenGeneral.self, rr) }
                if v == nil, let vv = dataNode["ventanillas"] as? [[String: Any]] { v = try? decodeArray([VentanillaRow].self, vv) }
                if i == nil, let ii = dataNode["insights"] as? [String: Any] { i = try? decodeDict(InsightsGemini.self, ii) }
            }
            return ExecResponse(resumen: r, ventanillas: v, insights: i)
        } else {
            return try JSONDecoder().decode(ExecResponse.self, from: data)
        }
    }

    private func decodeDict<T: Decodable>(_ type: T.Type, _ dict: [String: Any]) throws -> T {
        let d = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(T.self, from: d)
    }

    private func decodeArray<T: Decodable>(_ type: T.Type, _ arr: [[String: Any]]) throws -> T {
        let d = try JSONSerialization.data(withJSONObject: arr)
        return try JSONDecoder().decode(T.self, from: d)
    }
}

@MainActor
final class PromptVM: ObservableObject {
    enum Reveal: Equatable { case none, resumen, ventanillas, insights, todo }

    @Published var prompt: String = ""
    @Published var reveal: Reveal = .none
    @Published var isLoading = false
    @Published var error: String?
    @Published var resumen: ResumenGeneral?
    @Published var ventanillas: [VentanillaRow] = []
    @Published var insights: InsightsGemini?
    @Published var rawAnswer: String?

    private let service = ReporteService()

    func submit() {
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return }
        switch p.lowercased() {
        case "resumen": reveal = .resumen
        case "ventanillas": reveal = .ventanillas
        case "todo": reveal = .todo
        default: reveal = .insights
        }
        Task { await load() }
    }

    func load() async {
        error = nil
        rawAnswer = nil
        isLoading = true
        defer { isLoading = false }
        do {
            if reveal == .resumen || reveal == .ventanillas || reveal == .todo {
                let exec = try await service.fetchExecutive()
                if let r = exec.resumen { resumen = r }
                if let v = exec.ventanillas { ventanillas = v }
                if reveal == .todo, let i = exec.insights { insights = i }
            }
            if reveal == .insights {
                let flex = try await service.askGemini(prompt: prompt)
                self.insights = flex.insights
                self.rawAnswer = flex.rawText
            }
        } catch {
            if let e = error as NSError?, e.domain == "HTTP" {
                let body = (e.userInfo["body"] as? String) ?? ""
                self.error = "HTTP \(e.code): \(body.prefix(200))"
            } else {
                self.error = error.localizedDescription
            }
        }
    }
}


struct DashboardAdminView: View {
    @StateObject private var vm = PromptVM()
    @EnvironmentObject var router: AdminRouter
    @Binding var loggedIn: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(content)
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 22) {
            HStack {
                TextField("Pregunta a Gemini o escribe: resumen | ventanillas | todo", text: $vm.prompt)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit { vm.submit() }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
                    .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 4)
                
                Button { vm.submit() } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .padding(12)
                        .background(Circle().fill(Color.accentColor.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            
            if let error = vm.error, vm.reveal == .none {
                Text(error)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Group {
                switch vm.reveal {
                case .none:
                    HintCard()
                case .resumen:
                    if let r = vm.resumen { CardResumen(resumen: r) }
                case .ventanillas:
                    if !vm.ventanillas.isEmpty { CardVentanillas(ventanillas: vm.ventanillas) }
                case .insights:
                    if let i = vm.insights {
                        CardInsights(insights: i)
                            .padding(.horizontal, 20)
                    } else if let raw = vm.rawAnswer, !raw.isEmpty {
                        ScrollView {
                            Text(raw)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Text("Esperando respuesta de IA…")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                case .todo:
                    VStack(spacing: 14) {
                        if let r = vm.resumen { CardResumen(resumen: r) }
                        if !vm.ventanillas.isEmpty { CardVentanillas(ventanillas: vm.ventanillas) }
                        if let i = vm.insights {
                            CardInsights(insights: i)
                        } else if let raw = vm.rawAnswer, !raw.isEmpty {
                            ScrollView {
                                Text(raw)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            if vm.isLoading {
                ProgressView("Cargando…")
                    .padding(.top, 6)
            }
            
            Spacer()
        }
    }
}


private struct HintCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Este panel responde a tu prompt.")
                .font(.headline)
            Text("Prueba con:")
            VStack(alignment: .leading, spacing: 4) {
                Text("• resumen — métricas generales 24h")
                Text("• ventanillas — desglose por ventanilla")
                Text("• todo — todo lo anterior")
                Text("• cualquier pregunta libre para Gemini")
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
                    Text(items[i]).fixedSize(horizontal: false, vertical: true)
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


