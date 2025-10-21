import SwiftUI

struct EmpleadoTabView: View {
    @Binding var permisos: String
    @Binding var idempleado: Int
    @Binding var loggedIn: Bool
    
    @StateObject private var apiContainer = APIContainer(
        client: HTTPAdminAPI(baseURL: URL(string: "https://los-cinco-informaticos.tc2007b.tec.mx:10206")!)
    )
    @StateObject private var router = EmpleadoRouter()

    var body: some View {
        Group {
            if loggedIn {
                TabView(selection: $router.selected) {
                    NavigationStack(path: $router.togglePath) {
                        TurnoRapidoAdminView(loggedIn: $loggedIn,idempleado: idempleado, permisos: permisos, api: apiContainer.client)
                    }
                    .tabItem { Label("Turnos", systemImage: "switch.2") }
                    .tag(EmpleadoTab.TurnoRapidoAdminView)

                    NavigationStack(path: $router.nextTurnPath) {
                        nextturnView(idempleado: idempleado, permisos: permisos, api: apiContainer.client)
                    }
                    .tabItem { Label("Siguente Turnos", systemImage: "arrowtriangle.right.circle") }
                    .tag(EmpleadoTab.nextturn)

                }
                .tint(AdminColors.marca)
                .environmentObject(router)
                .onChange(of: router.selected) { router.popToRoot($0) }
                .globalExecutiveBot()
            } else {
                LoginAdminView(
                    loggedIn: $loggedIn,
                    idempleado: $idempleado,
                    permisos: $permisos
                )
            }
        }
    }
}

#Preview {
    EmpleadoTabView(permisos: .constant("Emp"), idempleado: .constant(25), loggedIn: .constant(false))
}

#Preview {
    EmpleadoTabView(permisos: .constant("Emp"), idempleado: .constant(25), loggedIn: .constant(true))
}
