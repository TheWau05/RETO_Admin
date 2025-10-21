import SwiftUI

struct LoginAdminView: View {
    // Bindings requeridos
    @Binding var loggedIn: Bool
    @Binding var idempleado: Int
    @Binding var permisos: String

    // Estado local
    @State private var usuario: String = ""
    @State private var contrasena: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = "Usuario o contraseña incorrectos."
    @State private var isLoading: Bool = false

    @EnvironmentObject var router: AdminRouter

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Image("LogoNova2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 215)

                TextField("Usuario", text: $usuario)
                    .font(.system(size: 40))
                    .padding()
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)

                SecureField("Contraseña", text: $contrasena)
                    .font(.system(size: 40))
                    .padding()
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)

                BotonPrincipal(title: isLoading ? "Ingresando..." : "Iniciar Sesión") {
                    Task {
                        let u = usuario.trimmingCharacters(in: .whitespacesAndNewlines)
                        let p = contrasena.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !u.isEmpty, !p.isEmpty else {
                            alertMessage = "Por favor ingresa usuario y contraseña."
                            showAlert = true
                            return
                        }

                        isLoading = true
                        defer { isLoading = false }

                        do {
                            let result = try await fetchLogin(username: u, password: p)
                            guard let perms = result.permissions, let emp = result.empid else {
                                alertMessage = "Respuesta inválida del servidor."
                                showAlert = true
                                return
                            }
                            guard perms == "Admin" || perms == "Emp" else {
                                alertMessage = "Permisos insuficientes. Se requiere 'Emp' o 'Admin'."
                                showAlert = true
                                return
                            }

                            await MainActor.run {
                                self.permisos = perms
                                self.idempleado = emp
                                self.loggedIn = true
                            }
                            
                            
                        } catch {
                            alertMessage = error.localizedDescription.isEmpty
                                ? "Error al procesar el login."
                                : error.localizedDescription
                            showAlert = true
                        }

                    }
                }
                .padding()
                .disabled(isLoading)
            }
            .alert("Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(alertMessage)
            })
        }
    }
}

#Preview {
    LoginAdminView(loggedIn: .constant(false),
                   idempleado: .constant(0),
                   permisos: .constant(""))
        .environmentObject(AdminRouter())
}
