//
//  MockAdminAPI.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

extension EmployeeBasic {
    init(id: Int, name: String) { self.id = id; self.name = name }
}

final class MockAdminAPI: AdminAPI {
    // Ventanillas
    func openVentanilla(ventanillaId: Int, empId: Int) async throws { }
    func closeVentanilla(ventanillaId: Int) async throws { }

    // Empleados
    func unassignedEmployees() async throws -> [EmployeeBasic] {
        [
            .init(id: 1, name: "Ana López"),
            .init(id: 2, name: "Bruno Díaz"),
            .init(id: 3, name: "Carla Ruiz"),
            .init(id: 4, name: "Diego Pérez"),
            .init(id: 5, name: "Eva García")
        ]
    }
}
