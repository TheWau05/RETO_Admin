//
//  Components.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI
import UIKit
import Foundation

// Paleta con namespace para evitar choques
enum AdminColors {
    static let marca      = Color(red: 1/255,   green: 104/255, blue: 138/255)
    static let acento     = Color(red: 255/255, green: 153/255, blue: 0/255)
    static let panel      = Color.gray.opacity(0.15)
    static let tabGray    = Color(UIColor.systemGray5)
    static let headerGray = Color.gray.opacity(0.18)
    static let text       = Color(UIColor.label)
}

// Espaciados y radios
struct AdminTheme {
    static let corner: CGFloat  = 20
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 16
}

// Botón principal reutilizable
struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(maxWidth: 520)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: AdminTheme.corner).fill(AdminColors.marca))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }
}

// Título de sección
struct SectionTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
    }
}

// Card de acción del dashboard
struct AdminActionCard: View {
    var title: String
    var systemImage: String
    var color: Color = AdminColors.marca
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.85))
                    .frame(width: 48, height: 48)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(RoundedRectangle(cornerRadius: 20).fill(color))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// Menú para elegir ventanilla 1..99
struct VentanillaMenu: View {
    var range: ClosedRange<Int> = 1...4
    @Binding var value: Int
    var onChange: () -> Void
    var body: some View {
        Menu {
            ForEach(Array(range), id: \.self) { n in
                Button("\(n)") { value = n; onChange() }
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundStyle(.gray)
                    .padding(.top, 6)
            }
        }
    }
}

// Grid de horas reutilizable
struct HourGrid: View {
    let hours: [String]
    @Binding var selected: String?
    let columns: [GridItem]
    var onPick: (String) -> Void
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(hours, id: \.self) { h in
                    Button {
                        selected = h
                        onPick(h)
                    } label: {
                        Text(h)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selected == h ? AdminColors.marca : Color.white)
                            )
                            .foregroundStyle(selected == h ? Color.white : Color.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selected == h ? .clear : Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }
}

// Estilo de barra de navegación gris
struct NavBarConfigurator: UIViewControllerRepresentable {
    var background: UIColor
    var title: UIColor
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = background
        a.titleTextAttributes = [.foregroundColor: title]
        a.largeTitleTextAttributes = [.foregroundColor: title]
        UINavigationBar.appearance().standardAppearance = a
        UINavigationBar.appearance().scrollEdgeAppearance = a
        UINavigationBar.appearance().tintColor = title
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    func navBarStyleGray() -> some View {
        background(NavBarConfigurator(
            background: UIColor(AdminColors.headerGray),
            title: UIColor(AdminColors.text)
        ))
    }
}
