//
//  ExecBotView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//
//
//  ExecBotView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//

import SwiftUI
import Foundation

struct ExecReportEN: Codable {
    let incidences: [String]
    let insights: [String]
    let recommendations: [String]

    enum CodingKeys: String, CodingKey {
        case incidences = "demand_peaks"
        case insights
        case recommendations
    }
}

private struct AskEnvelopeEN: Decodable {
    let prompt: String?
    let response: String?
}

final class ExecutiveServiceEN {
    private let base = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!
    private let cacheKey = "exec_report_cache_v1"

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 45
        cfg.timeoutIntervalForResource = 90
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: cfg)
    }()

    func loadCached() -> ExecReportEN? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(ExecReportEN.self, from: data)
    }

    func saveCached(_ report: ExecReportEN) {
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    func fetchExecutiveSummary() async throws -> ExecReportEN? {
        var req = URLRequest(url: base.appendingPathComponent("/reports/executive-summary"))
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("close", forHTTPHeaderField: "Connection")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "HTTP", code: code, userInfo: ["body": String(data: data, encoding: .utf8) ?? ""])
        }

        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
            return report
        }

        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let respStr = root["response"] as? String,
               let jsonData = respStr.data(using: .utf8),
               let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
                return report
            }
            if (root["response"] is NSNull),
               let sys = root["system_prompt"] as? String {
                return try await fetchFromAskGemini(using: sys)
            }
        }

        return nil
    }

    private func fetchFromAskGemini(using prompt: String) async throws -> ExecReportEN? {
        var req = URLRequest(url: base.appendingPathComponent("/ask/gemini"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["ask": prompt])

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }

        if let env = try? JSONDecoder().decode(AskEnvelopeEN.self, from: data),
           let respStr = env.response,
           let jsonData = respStr.data(using: .utf8),
           let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
            return report
        }

        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
            return report
        }

        return nil
    }
}

final class ExecutiveBotHub: ObservableObject {
    @Published var isPresented = false
}

struct GlobalExecutiveBot: ViewModifier {
    @StateObject private var hub = ExecutiveBotHub()
    private let service = ExecutiveServiceEN()

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                Spacer()
                HStack {
                    Button {
                        hub.isPresented = true
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title2.weight(.bold))
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 8)
                    }
                    .accessibilityLabel("Resumen Ejecutivo")
                    .padding(.leading, 22)
                    .padding(.bottom, 22)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $hub.isPresented) {
            ExecutiveDocSheetEN(service: service)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

extension View {
    func globalExecutiveBot() -> some View { modifier(GlobalExecutiveBot()) }
}

struct ExecutiveDocSheetEN: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var error: String?
    @State private var report: ExecReportEN?

    let service: ExecutiveServiceEN

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Cargando…").foregroundStyle(.secondary)
                    }
                } else if let error {
                    ScrollView {
                        Text(error).font(.callout).foregroundStyle(.secondary).padding()
                    }
                } else if let report {
                    ExecutiveDocumentViewEN(report: report)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Sin datos de Resumen Ejecutivo disponibles.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Resumen Ejecutivo")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualizar")
                }
            }
        }
        .onAppear { loadFromCache() }
    }

    private func loadFromCache() {
        error = nil
        report = service.loadCached()
    }

    private func refresh() async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            if let r = try await service.fetchExecutiveSummary() {
                report = r
                service.saveCached(r)
            } else {
                if report == nil { error = "No se pudo obtener el Executive Summary" }
            }
        } catch let e as NSError {
            if e.domain == "HTTP" {
                let body = (e.userInfo["body"] as? String) ?? ""
                error = "HTTP \(e.code): \(body.prefix(400))"
            } else {
                error = e.localizedDescription
            }
        }
    }
}

struct ExecutiveDocumentViewEN: View {
    let report: ExecReportEN

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionBlockEN(title: "Incidentes") {
                    BulletListEN(items: report.incidences)
                }
                SectionBlockEN(title: "Hallazgos") {
                    BulletListEN(items: report.insights)
                }
                SectionBlockEN(title: "Recomendaciones") {
                    BulletListEN(items: report.recommendations)
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }
}

struct SectionBlockEN<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

struct BulletListEN: View {
    let items: [String]
    var body: some View {
        if items.isEmpty {
            Text("—").foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(items[i]).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
