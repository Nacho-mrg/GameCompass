import SwiftUI
import FirebaseAuth

struct RegistrationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var username: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistered: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                //Fondo degradado con blur y opacidad
                LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), .black.opacity(0.9)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    //Logo elegante arriba
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .white.opacity(0.25), radius: 10, x: 0, y: 4)
                        .padding(.top)

                    //Título principal
                    Text("Crear una cuenta")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    //Campos de registro
                    VStack(spacing: 16) {
                        CustomTextField(iconName: "person.fill", placeholder: "Nombre de usuario", text: $username)
                        CustomTextField(iconName: "envelope.fill", placeholder: "Correo electrónico", text: $email)
                        CustomTextField(iconName: "lock.fill", placeholder: "Contraseña", text: $password, isSecure: true)
                        CustomTextField(iconName: "lock.fill", placeholder: "Confirmar contraseña", text: $confirmPassword, isSecure: true)
                    }
                    .padding(.horizontal)

                    //Botón de registro con animación
                    Button(action: register) {
                        Text("Registrarse")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [
                                    Color("buttonGradientStart"),
                                    Color("buttonGradientEnd")
                                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                            .scaleEffect(isRegistered ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRegistered)
                    }

                    NavigationLink(destination: MenuView().navigationBarBackButtonHidden(true), isActive: $isRegistered) {
                        EmptyView()
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    func register() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !username.isEmpty else {
            alertMessage = "Por favor, completa todos los campos."
            showAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "Las contraseñas no coinciden."
            showAlert = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                isRegistered = true
            }
        }
    }
}

#Preview {
    RegistrationView()
}
