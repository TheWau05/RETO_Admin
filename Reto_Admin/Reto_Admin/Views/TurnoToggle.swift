//
//  TurnoToggle.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 20/10/25.
//

import SwiftUI
import AVFoundation

// MARK: - Helpers para leer el snapshot de Abrir/Cerrar
private struct EmployeeMini_: Codable, Hashable { let id: Int; let name: String }
private struct ACVStateSnapshot_: Codable {
    var asignados: [Int: EmployeeMini_] = [:]     // ventanilla -> empleado
    var estados:   [Int: Bool] = [:]              // ventanilla -> cerrada(true)/abierta(false)
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

// MARK: - Píldora “Ventanilla X”
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

// MARK: - SOLO 2 estados: available / locked
private enum VisualState { case available, locked }

private struct StatusBadge: View {
    let state: VisualState
    @State private var pulse = false

    private var color: Color {
        switch state {
        case .available: return .green
        case .locked:    return .orange
        }
    }
    private var systemImage: String {
        switch state {
        case .available: return "checkmark.circle.fill"
        case .locked:    return "lock.fill"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 260, height: 260)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 6)
                        .scaleEffect(pulse && state == .locked ? 1.08 : 1.0)
                        .opacity(state == .locked ? (pulse ? 0.3 : 0.15) : 0)
                        .animation(state == .locked ?
                                   .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                                   value: pulse)
                )

            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: state == .locked ? 140 : 160, height: state == .locked ? 140 : 160)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .shadow(radius: 8)
        }
        .padding(.bottom, 8)
        .onAppear { pulse = true }
        .accessibilityHidden(true)
    }
}

// MARK: - Vista principal
struct TurnoRapidoAdminView: View {
    @EnvironmentObject private var router: EmpleadoRouter
    @Binding var loggedIn: Bool

    let idempleado: Int
    let permisos: String
    let api: any AdminAPI

    private let service = ServicioTurnoAdmin()

    @State private var turnoId: Int? = nil
    @State private var ventanillaId: Int? = nil
    @State private var cargando = false
    @State private var lockedByBackend = false
    @State private var showFinishSheet = false
    @State private var finishTurnoIdText = ""
    @State private var errorMsg: String? = nil
    @State private var activeAlert: ActiveAlert?

    private var isLocked: Bool { (turnoId != nil) || lockedByBackend }
    private var visualState: VisualState { isLocked ? .locked : .available }

    private var tituloEstado: String {
        switch visualState {
        case .available: return "Disponible"
        case .locked:    return "No disponible"
        }
    }

    private var puedeEmpezar: Bool {
        return !isLocked && !cargando && (ventanillaId ?? loadVentanillaFromSnapshot().vent) != nil
    }
    private var puedeFinalizar: Bool { (turnoId != nil) && !cargando }
    private var botonColor: Color { isLocked ? .orange : AdminColors.marca }

    // MARK: - Enum para ambas alertas
    enum ActiveAlert: Identifiable {
        case salir
        case error(String)

        var id: String {
            switch self {
            case .salir: return "salir"
            case .error(let msg): return "error-\(msg)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                VStack(spacing: 26) {
                    Spacer(minLength: 10)

                    // Info útil para depurar sesión (idempleado/permisos)
                    HStack(spacing: 12) {
                        Label("ID: \(idempleado)", systemImage: "person.crop.circle")
                        Label(permisos, systemImage: "key.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Chip de ventanilla o CTA para configurarla
                    if let v = ventanillaId ?? loadVentanillaFromSnapshot().vent {
                        VentChip(text: "Ventanilla \(v)")
                    } else {
                        Button {
                            router.switchTo(.abrircerrar)
                        } label: {
                            Label("Selecciona ventanilla en Abrir/Cerrar", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().stroke(Color.orange, lineWidth: 1.5))
                                .foregroundStyle(Color.orange)
                        }
                    }

                    StatusBadge(state: visualState)

                    // Título
                    Text(tituloEstado)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // Botón principal
                    Button { Task { await toggleTurno() } } label: {
                        Text(turnoId == nil ? "Empezar turno" : "Finalizar turno")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .frame(maxWidth: 720)
                            .padding(.vertical, 24)
                            .background(RoundedRectangle(cornerRadius: 22).fill(botonColor))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    }
                    .disabled(cargando || (turnoId == nil && !puedeEmpezar))
                    .opacity(cargando ? 0.6 : 1)

                    // Botón manual
                    Button {
                        onPressFinish()
                    } label: {
                        Label("Liberar turno (manual)", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(maxWidth: 720)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5)))
                            .foregroundStyle(.primary)
                    }
                    .disabled(cargando || (ventanillaId ?? loadVentanillaFromSnapshot().vent) == nil)
                    .sheet(isPresented: $showFinishSheet) { finishSheet }

                    // Subtexto
                    Group {
                        if let v = ventanillaId ?? loadVentanillaFromSnapshot().vent {
                            if let t = turnoId {
                                Text("Atendiendo turno \(t) en ventanilla \(v)")
                            } else if lockedByBackend {
                                Text("La ventanilla \(v) no está disponible actualmente")
                            } else {
                                Text("Listo para recibir en ventanilla \(v)")
                            }
                        } else {
                            Text("No hay ventanilla configurada.")
                        }
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)

                    // Botón de cerrar sesión
                    HStack {
                        Button(action: { activeAlert = .salir }) {
                            Image(systemName: "rectangle.portrait.and.arrow.forward.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.red)
                                .padding()
                        }
                    }

                    if cargando { ProgressView().scaleEffect(1.4) }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 60)
            }
            .navigationTitle("Turno rápido")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AdminColors.marca)
            // 🔔 ALERTA UNIFICADA
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .salir:
                    return Alert(
                        title: Text("Cerrar sesión"),
                        message: Text("¿Seguro que deseas cerrar sesión?"),
                        primaryButton: .destructive(Text("Cerrar sesión")) {
                            loggedIn = false
                        },
                        secondaryButton: .cancel()
                    )

                case .error(let message):
                    return Alert(
                        title: Text("Aviso"),
                        message: Text(message),
                        dismissButton: .default(Text("OK")) {
                            errorMsg = nil
                        }
                    )
                }
            }
            .task {
                let cache = service.loadCached()
                if let tid = cache.turno, let vid = cache.ventanilla {
                    withAnimation(.spring()) {
                        self.turnoId = tid
                        self.ventanillaId = vid
                        self.lockedByBackend = false
                    }
                } else {
                    let ctx = loadVentanillaFromSnapshot()
                    self.ventanillaId = ctx.vent
                    self.lockedByBackend = false
                }
            }
        }
    }

    // MARK: - Sheet de finish manual
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

    // MARK: - Acciones
    private func toggleTurno() async {
        do {
            cargando = true
            if let tid = turnoId, let vid = ventanillaId {
                try await service.finishService(turnoId: tid, ventanillaId: vid)
                service.clearCached()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    turnoId = nil
                    lockedByBackend = false
                }
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                let a = try await service.startService()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    turnoId = a.turnoId
                    ventanillaId = a.ventanillaId
                    lockedByBackend = false
                }
                service.saveCached(turno: a.turnoId, ventanilla: a.ventanillaId)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } catch let e as NSError {
            handleError(e)
        }
        cargando = false
    }

    private func onPressFinish() {
        if let tid = turnoId, let vid = ventanillaId ?? loadVentanillaFromSnapshot().vent {
            Task { await finishDirect(tid: tid, vid: vid) }
        } else {
            finishTurnoIdText = ""
            showFinishSheet = true
        }
    }

    private func finishDirect(tid: Int, vid: Int) async {
        do {
            cargando = true
            try await service.finishService(turnoId: tid, ventanillaId: vid)
            service.clearCached()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                turnoId = nil
                lockedByBackend = false
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } catch let e as NSError {
            handleError(e)
        }
        cargando = false
    }

    private func finishManual() async {
        guard let vid = ventanillaId ?? loadVentanillaFromSnapshot().vent,
              let tid = Int(finishTurnoIdText.trimmingCharacters(in: .whitespaces)) else {
            activeAlert = .error("Ingresa un turno_id válido.")
            return
        }
        showFinishSheet = false
        await finishDirect(tid: tid, vid: vid)
    }

    private func handleError(_ e: NSError) {
        let msg: String = (e.domain == "HTTP")
            ? "HTTP \(e.code): \((e.userInfo["body"] as? String) ?? "")"
            : e.localizedDescription

        activeAlert = .error(msg)

        if msg.localizedCaseInsensitiveContains("no está disponible")
            || msg.localizedCaseInsensitiveContains("not available") {
            withAnimation(.spring()) { lockedByBackend = true }
        }
    }
}
