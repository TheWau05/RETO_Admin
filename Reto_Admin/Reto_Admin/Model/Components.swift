//
//  Components.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 23/09/25.
//

import SwiftUI
import UIKit
import Foundation
import Charts

enum AdminColors {
    static let marca      = Color(red: 1/255,   green: 104/255, blue: 138/255)
    static let acento     = Color(red: 255/255, green: 153/255, blue: 0/255)
    static let panel      = Color.gray.opacity(0.15)
    static let tabGray    = Color(UIColor.systemGray5)
    static let headerGray = Color.gray.opacity(0.18)
    static let text       = Color(UIColor.label)
}

struct AdminTheme {
    static let corner: CGFloat  = 20
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 16
}

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
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
        }
    }
}

struct SectionTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black)
    }
}

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
                    .foregroundStyle(Color.white)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(RoundedRectangle(cornerRadius: 20).fill(color))
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }
}

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
                    .foregroundStyle(Color.black)
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundStyle(Color.gray)
                    .padding(.top, 6)
            }
        }
    }
}

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
                                    .stroke(selected == h ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }
}

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

struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(value)").font(.title.bold())
            ProgressView(value: value > 0 ? 1.0 : 0.0).tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DataTable: View {
    let headers: [String]
    let rows: [[String]]
    var columnWidth: CGFloat = 100
    var rowHeight: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(headers, id: \.self) { h in
                    cell(h, bold: true)
                        .background(AdminColors.marca.opacity(0.1))
                }
            }
            .background(AdminColors.marca.opacity(0.2))

            // Rows
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(rows[r], id: \.self) { v in
                        cell(v)
                    }
                }
                .background(r.isMultiple(of: 2) ? Color.clear : AdminColors.marca.opacity(0.05))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AdminColors.marca, lineWidth: 0.8))
    }

    @ViewBuilder
    private func cell(_ text: String, bold: Bool = false) -> some View {
        Text(text)
            .font(bold ? .caption.bold() : .caption)
            .foregroundColor(bold ? AdminColors.marca : .primary)
            .frame(width: columnWidth, height: rowHeight, alignment: .leading)
            .padding(.horizontal, 4)
            .overlay(Rectangle().stroke(AdminColors.marca.opacity(0.3), lineWidth: 0.5))
    }
}

// Header de página uniforme 
struct PageHeader<Trailing: View>: View {
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(AdminColors.text)
            Spacer()
            trailing()
        }
        .padding(.top, 8)
    }
}

struct TurnosChart: View {
    let title: String
    let orderedHours: [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            
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
    }
}
