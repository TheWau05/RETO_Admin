//
//  TablesBlock.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 25/09/25.
//

import SwiftUI
import UIKit

// MARK: - TablesBlock (full-width table)
struct TablesBlock: View {
    private let ventHeaders = ["Número de Ventanilla", "Tiempo en Servicio", "Tiempo de Espera"]
    private let empHeaders  = ["Empleado", "Tiempo en Servicio", "Tiempo de Espera"]

    // Sample data (for testing)
    private let venRows: [[String]] = [
        ["1", "12", "5"],
        ["2", "10", "6"],
        ["3", "14", "8"],
        ["4", "11", "7"]
    ]
    private let empRows: [[String]] = [
        ["Ana López", "9", "4"],
        ["Carlos Díaz", "12", "6"],
        ["Laura Méndez", "10", "5"],
        ["Roberto Cruz", "13", "7"]
    ]

    var body: some View {
        VStack(spacing: 24) {
            TableCard(title: "Promedios por ventanilla", headers: ventHeaders, rows: venRows)
            TableCard(title: "Promedios por empleado",   headers: empHeaders,  rows: empRows)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .tint(Color.marca)
    }
}

// MARK: - Card container (kept simple to avoid type-check blowups)
private struct TableCard: View {
    let title: String
    let headers: [String]
    let rows: [[String]]

    // Equal, flexible columns across available width
    private var cols: [GridItem] {
        Array(repeating: .init(.flexible(minimum: 60), spacing: 0), count: headers.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                HeaderGrid(headers: headers, cols: cols)

                if rows.isEmpty {
                    EmptyRowView(colCount: headers.count)
                } else {
                    ForEach(rows.indices, id: \.self) { r in
                        RowGrid(values: rows[r], headersCount: headers.count, cols: cols)
                            .background(r.isMultiple(of: 2) ? Color.black.opacity(0.03) : Color.clear)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity) // table fills card width
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Header grid
private struct HeaderGrid: View {
    let headers: [String]
    let cols: [GridItem]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 0) {
            ForEach(Array(headers.enumerated()), id: \.offset) { (i, h) in
                HeaderCell(
                    text: h,
                    alignLeading: i == 0
                )
            }
        }
    }
}

private struct HeaderCell: View {
    let text: String
    let alignLeading: Bool

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.marca)
            .lineLimit(1)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: alignLeading ? .leading : .center)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.black.opacity(0.05)), alignment: .bottom)
            .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.black.opacity(0.05)), alignment: .trailing)
    }
}

// MARK: - Data rows
private struct RowGrid: View {
    let values: [String]
    let headersCount: Int
    let cols: [GridItem]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 0) {
            ForEach(0..<headersCount, id: \.self) { c in
                DataCell(
                    text: c < values.count ? values[c] : "—",
                    alignLeading: c == 0
                )
            }
        }
    }
}

private struct DataCell: View {
    let text: String
    let alignLeading: Bool

    var body: some View {
        Text(text)
            .font(alignLeading ? .subheadline : .subheadline.monospacedDigit())
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: alignLeading ? .leading : .center)
            .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.black.opacity(0.05)), alignment: .trailing)
    }
}

// MARK: - Empty state
private struct EmptyRowView: View {
    let colCount: Int
    var body: some View {
        HStack {
            Text("Sin datos para mostrar")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
            Spacer(minLength: 0)
        }
        .background(Color.black.opacity(0.02))
    }
}

