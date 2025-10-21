import SwiftUI

fileprivate let uiDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

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

struct nextturnView: View {
    let idempleado: Int
    let permisos: String
    let api: any AdminAPI

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
                    // (Opcional) útil para depurar sesión
                    HStack(spacing: 12) {
                        Label("ID: \(idempleado)", systemImage: "person")
                        Label(permisos, systemImage: "key.fill")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)


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
                    .refreshable { await refresh() }
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
                        if isLoading { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Actualizar lista")
                }
            }
        }
        .task { await refresh() }
    }

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

#Preview {
    nextturnView(idempleado: 25, permisos: "Emp", api: MockAdminAPI())
}
