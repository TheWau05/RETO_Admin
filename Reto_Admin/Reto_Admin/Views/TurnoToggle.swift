//
//  TurnoToggle.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//
import SwiftUI
import AVFoundation

// ===== helpers snapshot (autocontenidos) =====
private struct EmployeeMini_: Codable, Hashable { let id: Int; let name: String }
private struct ACVStateSnapshot_: Codable {
    var asignados: [Int: EmployeeMini_] = [:]
    var estados:   [Int: Bool] = [:]
    var ventanillaSeleccionada: Int = 1
}
private let kACVDefaultsKey_ = "AbrirCerrarVentanilla_State_v2"

@inline(__always)
private func loadVentanillaFromSnapshot() -> (vent: Int?, emp: Int?) {
    guard let data = UserDefaults.standard.data(forKey: kACVDefaultsKey_),
          let snap = try? JSONDecoder().decode(ACVStateSnapshot_.self, from: data) else {
        return (nil, nil)
    }
    let v = snap.ventanillaSeleccionada
    let e = snap.asignados[v]?.id
    return (v, e)
}

// ===== UI minis =====
private struct VentChip: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.grid.1x2.fill")
            Text(text).font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(AdminColors.marca))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

private struct StatusBadge: View {
    let color: Color
    let systemImage: String
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.15)).frame(width: 260, height: 260)
            Image(systemName: systemImage)
                .resizable().scaledToFit().frame(width: 160, height: 160)
                .foregroundStyle(color).symbolRenderingMode(.hierarchical)
                .shadow(radius: 8)
        }
        .padding(.bottom, 8)
        .accessibilityHidden(true)
    }
}

// ===== Vista principal =====
struct TurnoRapidoAdminView: View {
    @EnvironmentObject private var router: AdminRouter
    private let service = ServicioTurnoAdmin()

    @State private var turnoId: Int? = nil
    @State private var ventanillaId: Int? = nil
    @State private var empId: Int? = nil

    @State private var cargando = false
    @State private var errorMsg: String? = nil

    // estado UI
    @State private var estadoForzadoNoDisponible = false
    @State private var showFinishSheet = false
    @State private var finishTurnoIdText = ""

    private var activo: Bool { turnoId != nil && ventanillaId != nil }
    private var tituloEstado: String {
        if estadoForzadoNoDisponible { return "No disponible" }
        return activo ? "Atendiendo" : "Disponible"
    }
    private var colorEstado: Color {
        if estadoForzadoNoDisponible { return .gray }
        return activo ? .orange : .green
    }
    private var iconoEstado: String {
        if estadoForzadoNoDisponible { return "exclamationmark.triangle.fill" }
        return activo ? "clock.badge.exclamationmark" : "checkmark.circle.fill"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                VStack(spacing: 26) {
                    Spacer(minLength: 10)

                    if let v = ventanillaId ?? loadVentanillaFromSnapshot().vent {
                        VentChip(text: "Ventanilla \(v)")
                    } else {
                        Button {
                            router.switchTo(.abrirCerrar)
                        } label: {
                            Label("Selecciona ventanilla en Abrir/Cerrar", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().stroke(Color.orange, lineWidth: 1.5))
                                .foregroundStyle(Color.orange)
                        }
                    }

                    StatusBadge(color: colorEstado, systemImage: iconoEstado)

                    Text(tituloEstado)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(estadoForzadoNoDisponible ? .gray : .primary)

                    // Botón principal (toggle)
                    Button { Task { await toggleTurno() } } label: {
                        Text(activo ? "Finalizar turno" : "Empezar turno")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .frame(maxWidth: 720)
                            .padding(.vertical, 24)
                            .background(RoundedRectangle(cornerRadius: 22).fill(AdminColors.marca))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    }
                    .disabled(cargando || loadVentanillaFromSnapshot().vent == nil || estadoForzadoNoDisponible)
                    .opacity(cargando ? 0.6 : 1)

                    // NUEVO: Botón explícito para FINISH / liberar
                    Button {
                        onPressFinish()
                    } label: {
                        Label("Liberar (finish)", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(maxWidth: 720)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5)))
                            .foregroundStyle(.primary)
                    }
                    .disabled(cargando || (ventanillaId ?? loadVentanillaFromSnapshot().vent) == nil)
                    .sheet(isPresented: $showFinishSheet) {
                        finishSheet
                    }

                    // Subtexto
                    Group {
                        if let v = ventanillaId ?? loadVentanillaFromSnapshot().vent {
                            Text(estadoForzadoNoDisponible
                                 ? "La ventanilla \(v) no está disponible actualmente"
                                 : activo ? "Atendiendo en ventanilla \(v)" : "Listo para recibir en ventanilla \(v)")
                        } else {
                            Text("No hay ventanilla configurada.")
                        }
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)

                    if cargando { ProgressView().scaleEffect(1.4) }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 60)
            }
            .navigationTitle("Turno rápido")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AdminColors.marca)
            .alert("Aviso", isPresented: .constant(errorMsg != nil)) {
                Button("OK") { errorMsg = nil }
            } message: { Text(errorMsg ?? "") }
            .task {
                let cache = service.loadCached()
                turnoId = cache.turno
                ventanillaId = cache.ventanilla
                let ctx = loadVentanillaFromSnapshot()
                if ventanillaId == nil { ventanillaId = ctx.vent }
                empId = ctx.emp
            }
        }
    }

    // MARK: - Finish sheet
    private var finishSheet: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text("Finalizar turno manual")
                    .font(.headline)
                Text("Si el turno quedó atorado en el servidor, ingresa el **turno_id** para liberar la ventanilla.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("turno_id", text: $finishTurnoIdText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button {
                    Task { await finishManual() }
                } label: {
                    Text("Finalizar ahora")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(AdminColors.marca))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cerrar") { showFinishSheet = false } }
            }
        }
    }

    // MARK: - Actions
    private func onPressFinish() {
        // Si tenemos ambos IDs -> finish directo
        if let tid = turnoId, let vid = ventanillaId ?? loadVentanillaFromSnapshot().vent {
            Task { await finishDirect(tid: tid, vid: vid) }
        } else {
            // Falta turno_id -> pedirlo
            finishTurnoIdText = ""
            showFinishSheet = true
        }
    }

    private func finishDirect(tid: Int, vid: Int) async {
        do {
            cargando = true
            try await service.finishService(turnoId: tid, ventanillaId: vid)
            service.clearCached()
            turnoId = nil
            ventanillaId = vid  // conserva ventanilla visible
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } catch let e as NSError {
            if e.domain == "HTTP" {
                errorMsg = "HTTP \(e.code): \((e.userInfo["body"] as? String) ?? "")"
            } else {
                errorMsg = e.localizedDescription
            }
        }
        cargando = false
    }

    private func finishManual() async {
        guard let vid = ventanillaId ?? loadVentanillaFromSnapshot().vent,
              let tid = Int(finishTurnoIdText.trimmingCharacters(in: .whitespaces)) else {
            errorMsg = "Ingresa un turno_id válido."
            return
        }
        showFinishSheet = false
        await finishDirect(tid: tid, vid: vid)
    }

    private func toggleTurno() async {
        do {
            cargando = true
            estadoForzadoNoDisponible = false

            if activo, let tid = turnoId, let vid = ventanillaId {
                try await service.finishService(turnoId: tid, ventanillaId: vid)
                service.clearCached()
                turnoId = nil
            } else {
                let a = try await service.startService()
                turnoId = a.turnoId
                ventanillaId = a.ventanillaId
                service.saveCached(turno: a.turnoId, ventanilla: a.ventanillaId)
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } catch let e as NSError {
            let msg: String
            if e.domain == "HTTP" {
                msg = "HTTP \(e.code): \((e.userInfo["body"] as? String) ?? "")"
            } else {
                msg = e.localizedDescription
            }
            errorMsg = msg
            if msg.localizedCaseInsensitiveContains("no está disponible") ||
               msg.localizedCaseInsensitiveContains("not available") {
                estadoForzadoNoDisponible = true
            }
        }
        cargando = false
    }
}
