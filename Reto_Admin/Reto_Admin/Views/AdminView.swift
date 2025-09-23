//
//  AdminView.swift
//  Reto_Admin
//
//  Created by 박진혁 on 9/23/25.
//

import SwiftUI

struct AdminView: View {
    var body: some View {
        ContentUnavailableView("Admin",
                               systemImage: "gearshape",
                               description: Text("Pantalla en blanco por ahora."))
            .navigationTitle("Admins")
    }
}

#Preview { NavigationStack { AdminView() } }

