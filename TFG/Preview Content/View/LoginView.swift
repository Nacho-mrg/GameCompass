import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                //Fondo degradado
                LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), Color.black.opacity(0.9)]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Tarjeta de login
                    VStack(spacing: 20) {
                        // Logo
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                            .padding(.top)

                        Text("Bienvenido")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("things"))

                        Text("Inicia sesión para continuar")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        CustomTextField(iconName: "envelope.fill", placeholder: "Correo electrónico", text: $email)

                        HStack {
                            CustomTextField(iconName: "lock.fill", placeholder: "Contraseña", text: $password, isSecure: !isPasswordVisible)

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(Color("things"))
                            }
                        }
                        .padding(.horizontal)

                        Button(action: signInWithEmail) {
                            Text("Ingresar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("ButtonColor"))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }

                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .foregroundColor(.white)
                                Text("Ingresar con Google")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("ButtonColor").opacity(0.85))
                            .cornerRadius(12)
                        }

                        NavigationLink(destination: RegistrationView()) {
                            Text("¿No tienes cuenta? Regístrate")
                                .font(.footnote)
                                .foregroundColor(Color("things"))
                                .underline()
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .shadow(radius: 20)

                    Spacer()

                    NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
                        EmptyView()
                    }
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }

    func signInWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Por favor, completa todos los campos."
            showAlert = true
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = authResult?.user {
                UserDefaults.standard.set(user.uid, forKey: "userUID")
                isLoggedIn = true
            }
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            alertMessage = "No se pudo obtener el Client ID de Firebase."
            showAlert = true
            return
        }

        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            alertMessage = "No se pudo obtener la ventana principal."
            showAlert = true
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                alertMessage = "No se pudo obtener el usuario o el token."
                showAlert = true
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                } else if let user = authResult?.user {
                    UserDefaults.standard.set(user.uid, forKey: "userUID")
                    isLoggedIn = true
                }
            }
        }
    }
}

struct CustomTextField: View {
    var iconName: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(Color("things"))

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color("things"))
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color("things"))
            }
        }
        .padding()
        .background(Color("backgroundComponent").opacity(0.8))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
}

