import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegistrationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var username: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistered: Bool = false

    // Nivel de seguridad de la contraseña (0.0 a 1.5)
    private var passwordStrength: CGFloat {
        PasswordStrengthEvaluator.evaluate(password: password)
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 0..<0.33: return "Débil"
        case 0.33..<0.66: return "Media"
        default: return "Fuerte"
        }
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0..<0.33: return .red
        case 0.33..<0.66: return .orange
        default: return .green
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), .black.opacity(0.9)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .white.opacity(0.25), radius: 10, x: 0, y: 4)
                        .padding(.top)

                    Text("Crear una cuenta")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(spacing: 16) {
                        CustomTextField(iconName: "person.fill", placeholder: "Nombre de usuario", text: $username)
                        CustomTextField(iconName: "envelope.fill", placeholder: "Correo electrónico", text: $email)
                        CustomTextField(iconName: "lock.fill", placeholder: "Contraseña", text: $password, isSecure: true)
                        CustomTextField(iconName: "lock.fill", placeholder: "Confirmar contraseña", text: $confirmPassword, isSecure: true)

                        // Barra de seguridad
                        VStack(alignment: .leading, spacing: 6) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                        .frame(height: 10)

                                    LinearGradient(
                                        gradient: Gradient(colors: [strengthColor.opacity(0.9), strengthColor.opacity(0.6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: geometry.size.width * min(passwordStrength, 1.0), height: 10)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(color: strengthColor.opacity(0.4), radius: 4, x: 0, y: 2)
                                    .animation(.easeInOut(duration: 0.35), value: passwordStrength)
                                }
                            }
                            .frame(height: 10)
                            .padding(.horizontal, 4)

                            HStack(spacing: 6) {
                                Image(systemName: passwordStrength < 0.33 ? "exclamationmark.triangle.fill" :
                                      passwordStrength < 0.66 ? "lock.fill" :
                                      "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(strengthColor)
                                Text(strengthLabel)
                                    .font(.caption)
                                    .foregroundColor(strengthColor)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)

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

                    // 🔹 NavigationLink oculto para ir al menú sin botón atrás
                    NavigationLink(
                        destination: ContentView()
                            .navigationBarBackButtonHidden(true)
                            .navigationBarHidden(true),
                        isActive: $isRegistered
                    ) {
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
            } else if let user = authResult?.user {
                // 🔹 Guardar el username en Firestore usando el UID
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "displayName": username,
                    "email": email
                ]
                db.collection("users").document(user.uid).setData(userData, merge: true) { error in
                    if let error = error {
                        alertMessage = "Error guardando datos: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        // Actualizar Auth displayName
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = username
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error actualizando Auth displayName: \(error.localizedDescription)")
                            }
                        }
                        isRegistered = true
                    }
                }
            }
        }
    }
}

// MARK: - Evaluador de fortaleza de contraseña
struct PasswordStrengthEvaluator {
    static func evaluate(password: String) -> CGFloat {
        guard !password.isEmpty else { return 0 }
        var strength: CGFloat = 0
        if password.count >= 6 { strength += 0.3 }
        if password.count >= 10 { strength += 0.2 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 0.2 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 0.15 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { strength += 0.15 }
        return min(strength, 1.0)
    }
}

#Preview {
    RegistrationView()
}

