//
//  nextturn.swift
//  Reto_Admin
//
//  Created by 박진혁 on 10/21/25.
//

import SwiftUI

// ===========================================================
// MARK: - DTO that matches your API (unchanged keys)
// ===========================================================
private struct TurnoDTO: Decodable {
    let id: Int
    let usrId: Int
    let scheduledDate: Date
    let status: Bool
    let prescriptionId: String?
    let comentariosReceta: String?
    let comentariosCancelacion: String?

    enum CodingKeys: String, CodingKey {
        case id                = "Id"
        case usrId             = "Usr_Id"
        case scheduledDate     = "Scheduled_Date"
        case status            = "Status"
        case prescriptionId    = "Perscription_Id"       // spelling as in JSON
        case comentariosReceta = "Comentarios_Receta"
        case comentariosCancelacion = "Comentarios_Cancelacion"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id     = try c.decode(Int.self,    forKey: .id)
        usrId  = try c.decode(Int.self,    forKey: .usrId)
        status = try c.decode(Bool.self,   forKey: .status)
        prescriptionId         = try? c.decode(String.self, forKey: .prescriptionId)
        comentariosReceta      = try? c.decode(String.self, forKey: .comentariosReceta)
        comentariosCancelacion = try? c.decode(String.self, forKey: .comentariosCancelacion)

        // RFC 1123 date, e.g. "Mon, 20 Oct 2025 15:47:43 GMT"
        let raw = try c.decode(String.self, forKey: .scheduledDate)
        guard let parsed = DateFormatter.rfc1123.date(from: raw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .scheduledDate, in: c,
                debugDescription: "Expected RFC1123 date like 'Mon, 20 Oct 2025 15:47:43 GMT', got: \(raw)"
            )
        }
        scheduledDate = parsed
    }
}

// RFC-1123 date formatter
private extension DateFormatter {
    static let rfc1123: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return df
    }()
}

// ===========================================================
// MARK: - View Model / Networking
// ===========================================================
struct Record: Identifiable, Hashable {
    let id: Int
    var perscriptionId: String           // shown instead of User
    var comentariosReceta: String?       // new column
    var date: Date
    var isDone: Bool
}

private enum TurnosAPI {
    static let url = URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206/turnos/next30")!

    static func fetchNext30() async throws -> [Record] {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Endpoint returns a bare array
        let items = try JSONDecoder().decode([TurnoDTO].self, from: data)

        return items.map { dto in
            Record(
                id: dto.id,
                perscriptionId: dto.prescriptionId ?? "—",
                comentariosReceta: dto.comentariosReceta,   // may be nil
                date: dto.scheduledDate,
                isDone: dto.status
            )
        }
    }
}

// UI date formatter
fileprivate let uiDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

//UI

// Column header
private struct RecordHeader: View {
    var body: some View {
        HStack(spacing: 20) {
            Text("ID").font(.title2.weight(.bold)).frame(width: 80, alignment: .leading)
            Text("Receta Id").font(.title2.weight(.bold)).frame(width: 180, alignment: .leading)
            Text("Comentarios").font(.title2.weight(.bold)).frame(maxWidth: .infinity, alignment: .leading)
            Text("Horarios").font(.title2.weight(.bold)).frame(width: 240, alignment: .leading)
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider().padding(.top, 8) }
    }
}

// Row
private struct RecordRow: View {
    @Binding var record: Record

    var body: some View {
        HStack(spacing: 20) {
            Text("#\(record.id)")
                .font(.title2.monospacedDigit())
                .frame(width: 80, alignment: .leading)

            Text(record.perscriptionId)
                .font(.title2)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(record.comentariosReceta ?? "—")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(uiDateFormatter.string(from: record.date))
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 240, alignment: .leading)
                .lineLimit(1)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Divider().opacity(0.6) }
    }
}

// Main view (Exec-style refresh applied)
struct nextturnView: View {
    @State private var records: [Record] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Text("User Records")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    if let errorMessage {
                        Text(errorMessage).font(.callout).foregroundStyle(.red)
                    }

                    RecordHeader()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if isLoading && records.isEmpty {
                                ProgressView().padding(.vertical, 32)
                            }
                            ForEach($records) { $rec in
                                RecordRow(record: $rec)
                            }
                        }
                    }
                    .refreshable { await refresh() }  // pull-to-refresh uses same exec-style refresh
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 24)
                .frame(maxWidth: 950)
            }
            .navigationTitle("Siguiente Turno")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Actualizar lista")
                }
            }
        }
        .task { await refresh() } // first load on appear (exec-style)
    }

    // Exec-style refresh function
    private func refresh() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await TurnosAPI.fetchNext30()
        } catch {
            errorMessage = "Formato no válido o error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
#Preview { nextturnView() }
