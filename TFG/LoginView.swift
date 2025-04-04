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
                Color("backgroundApp")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Iniciar Sesión")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color("things"))
                    
                    Image("logo")
                        .resizable()
                        .frame(width: 250, height: 250)
                        .cornerRadius(70)
                    
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
                            .frame(width: 250, height: 50)
                            .background(Color("ButtonColor"))
                            .cornerRadius(25)
                    }
                    
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.white)
                            Text("Ingresar con Google")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 250, height: 50)
                        .background(Color("ButtonColor"))
                        .cornerRadius(25)
                    }
                    
                    NavigationLink(destination: RegistrationView()) {
                        Text("Registrarse")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 250, height: 50)
                            .background(Color("ButtonColor"))
                            .cornerRadius(25)
                    }
                    
                    NavigationLink(destination: MenuView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
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
            } else {
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
                } else {
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
        .background(Color("backgroundComponent"))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
}

