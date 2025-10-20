//
//  ExecBotView.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//
import SwiftUI
import Foundation

// =====================================================
// 1) Modelo del Executive Summary (match con Python)
// =====================================================
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


// Envelope opcional para /ask/gemini
private struct AskEnvelopeEN: Decodable {
    let prompt: String?
    let response: String?
}

// =====================================================
// 2) Service: GET /reports/executive-summary  (+ fallback /ask/gemini)
// =====================================================
//final class ExecutiveServiceEN {
//    private let base = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!
//
//    private lazy var session: URLSession = {
//        let cfg = URLSessionConfiguration.default
//        cfg.waitsForConnectivity = true
//        cfg.timeoutIntervalForRequest = 45
//        cfg.timeoutIntervalForResource = 90
//        cfg.allowsConstrainedNetworkAccess = true
//        cfg.allowsExpensiveNetworkAccess = true
//        return URLSession(configuration: cfg)
//    }()
//
//    func fetchExecutiveSummary() async throws -> ExecReportEN? {
//        var req = URLRequest(url: base.appendingPathComponent("/reports/executive-summary"))
//        req.httpMethod = "GET"
//        req.setValue("application/json", forHTTPHeaderField: "Accept")
//        req.setValue("close", forHTTPHeaderField: "Connection") // ayuda ante TCP RST
//
//        let (data, resp) = try await session.data(for: req)
//        guard let http = resp as? HTTPURLResponse else { return nil }
//        guard (200..<300).contains(http.statusCode) else {
//            let body = String(data: data, encoding: .utf8) ?? ""
//            throw NSError(domain: "HTTP", code: http.statusCode, userInfo: ["body": body])
//        }
//
//        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
//            return report
//        }
//
//        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//            if let respStr = root["response"] as? String,
//               let jsonData = respStr.data(using: .utf8),
//               let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
//                return report
//            }
//
//            if (root["response"] is NSNull),
//               let sys = root["system_prompt"] as? String {
//                return try await fetchFromAskGemini(using: sys)
//            }
//        }
//
//        return nil
//    }
//
//    private func fetchFromAskGemini(using prompt: String) async throws -> ExecReportEN? {
//        var req = URLRequest(url: base.appendingPathComponent("/ask/gemini"))
//        req.httpMethod = "POST"
//        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        req.setValue("application/json", forHTTPHeaderField: "Accept")
//        req.setValue("close", forHTTPHeaderField: "Connection")
//        req.httpBody = try JSONSerialization.data(withJSONObject: ["ask": prompt])
//
//        let (data, resp) = try await session.data(for: req)
//        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
//
//        if let env = try? JSONDecoder().decode(AskEnvelopeEN.self, from: data),
//           let respStr = env.response,
//           let jsonData = respStr.data(using: .utf8),
//           let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
//            return report
//        }
//
//        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
//            return report
//        }
//        return nil
//    }
//}

final class ExecutiveServiceEN {
    private let base = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 45
        cfg.timeoutIntervalForResource = 90
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: cfg)
    }()

    func fetchExecutiveSummary() async throws -> ExecReportEN? {
        var req = URLRequest(url: base.appendingPathComponent("/reports/executive-summary"))
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("close", forHTTPHeaderField: "Connection")

        print("🌐 [GET] /reports/executive-summary ...")
        let (data, resp) = try await session.data(for: req)

        // --- Print status and raw response ---
        if let http = resp as? HTTPURLResponse {
            print("✅ HTTP Status:", http.statusCode)
            print("📦 Headers:", http.allHeaderFields)
        }
        print("🧾 Raw Body:")
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        } else {
            print("(binary data, could not decode)")
        }

        // --- HTTP validation ---
        guard let http = resp as? HTTPURLResponse else { return nil }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "HTTP", code: http.statusCode,
                          userInfo: ["body": String(data: data, encoding: .utf8) ?? ""])
        }

        // --- Try direct decode ---
        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
            print("✅ Decoded ExecReportEN directly:", report)
            return report
        }

        // --- Try wrapped response ---
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🧩 Root JSON Keys:", root.keys)
            if let respStr = root["response"] as? String {
                print("🪶 Found 'response' field:", respStr.prefix(200), "...")
//                if let jsonData = respStr.data(using: .utf8),
//                   let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
//                    print("✅ Decoded ExecReportEN from 'response' string:", report)
//                    return report
//                }
                if let jsonData = respStr.data(using: .utf8) {
                    do {
                        let report = try JSONDecoder().decode(ExecReportEN.self, from: jsonData)
                        print("✅ Decoded ExecReportEN from 'response' string:", report)
                        return report
                    } catch {
                        print("❌ JSON decoding error:", error)
                        if let raw = String(data: jsonData, encoding: .utf8) {
                            print("Raw data that failed:", raw)
                        }
                    }
                }
            }

            if (root["response"] is NSNull),
               let sys = root["system_prompt"] as? String {
                print("🔁 Falling back to /ask/gemini with prompt:", sys.prefix(200))
                return try await fetchFromAskGemini(using: sys)
            }
        }

        print("⚠️ Could not decode response.")
        return nil
    }

    private func fetchFromAskGemini(using prompt: String) async throws -> ExecReportEN? {
        print("🌐 [POST] /ask/gemini ...")
        var req = URLRequest(url: base.appendingPathComponent("/ask/gemini"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["ask": prompt])

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse {
            print("✅ HTTP Status:", http.statusCode)
        }
        print("🧾 Gemini Body:", String(data: data, encoding: .utf8) ?? "(binary)")

        if let env = try? JSONDecoder().decode(AskEnvelopeEN.self, from: data),
           let respStr = env.response,
           let jsonData = respStr.data(using: .utf8),
           let report = try? JSONDecoder().decode(ExecReportEN.self, from: jsonData) {
            print("✅ Decoded ExecReportEN from Gemini response:", report)
            return report
        }

        if let report = try? JSONDecoder().decode(ExecReportEN.self, from: data) {
            print("✅ Decoded ExecReportEN directly from Gemini body:", report)
            return report
        }

        print("⚠️ Could not decode Gemini response.")
        return nil
    }
}


// =====================================================
// 3) Bot flotante + hoja (sheet)
// =====================================================
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
                    Spacer()
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
                    .accessibilityLabel("Executive summary")
                    .padding(.trailing, 22)
                    .padding(.bottom, 22)
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
    /// Aplícalo en tu ContentView:  .globalExecutiveBot()
    func globalExecutiveBot() -> some View { modifier(GlobalExecutiveBot()) }
}

// =====================================================
/* 4) Hoja que pinta el Executive Summary tal cual
      (incidences, outstanding_results, insights, recommendations) */
// =====================================================
struct ExecutiveDocSheetEN: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
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
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                } else if let report {
                    ExecutiveDocumentViewEN(report: report)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Sin datos de Executive Summary.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Executive summary")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualizar")
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        print("🚀 Starting load() for Executive Summary")

        do {
            let result = try await service.fetchExecutiveSummary()
            report = result
            if let report {
                print("✅ Report received successfully.")
                print("   Incidences:", report.incidences)
//                print("   Outstanding results:", report.outstanding_results)
                print("   Insights:", report.insights)
                print("   Recommendations:", report.recommendations)
            } else {
                print("⚠️ No report decoded (nil).")
                error = "No se pudo obtener el Executive Summary"
            }
        } catch let e as NSError {
            print("❌ Error in load():", e.domain, e.code, e.localizedDescription)
            if e.domain == "HTTP" {
                let body = (e.userInfo["body"] as? String) ?? ""
                self.error = "HTTP \(e.code): \(body.prefix(400))"
            } else {
                self.error = e.localizedDescription
            }
        }
    }

}

// =====================================================
// 5) Vista “documento” que muestra los 4 campos
// =====================================================
struct ExecutiveDocumentViewEN: View {
    let report: ExecReportEN

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionBlockEN(title: "Incidences") {
                    BulletListEN(items: report.incidences)
                }
//                SectionBlockEN(title: "Outstanding results") {
//                    BulletListEN(items: report.outstanding_results)
//                }
                SectionBlockEN(title: "Insights") {
                    BulletListEN(items: report.insights)
                }
                SectionBlockEN(title: "Recommendations") {
                    BulletListEN(items: report.recommendations)
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }
}

// Helpers visuales
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

