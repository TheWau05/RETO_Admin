//
//  APIContainer.swift
//  Reto_Admin
//
//  Created by Marco Ramos Jalife on 24/09/25.
//

import Foundation

final class APIContainer: ObservableObject {
    let client: AdminAPI
    init(client: AdminAPI) { self.client = client }
}
