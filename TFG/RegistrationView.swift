import SwiftUI
import FirebaseAuth

struct RegistrationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var username: String = "" // Nuevo campo de nombre de usuario
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistered: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Registro")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color("primaryText")) // Color personalizado desde los assets
            
            CustomTextField(iconName: "person.fill", placeholder: "Nombre de usuario", text: $username)
            CustomTextField(iconName: "envelope.fill", placeholder: "Correo electrónico", text: $email)
            CustomTextField(iconName: "lock.fill", placeholder: "Contraseña", text: $password, isSecure: true)
            CustomTextField(iconName: "lock.fill", placeholder: "Confirmar Contraseña", text: $confirmPassword, isSecure: true)
            
            Button(action: register) {
                Text("Registrarse")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color("buttonGradientStart"), Color("buttonGradientEnd")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) // Gradiente de colores personalizado
                    .cornerRadius(25)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5) // Sombra personalizada
                    .scaleEffect(1.1) // Efecto de animación de hover
                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: isRegistered) // Animación al presionar
            }
            .onTapGesture {
                withAnimation {
                    isRegistered.toggle()
                }
            }
            
            NavigationLink(destination: MenuView().navigationBarBackButtonHidden(true), isActive: $isRegistered) {
                EmptyView()
            }
            
            Spacer()
        }
        .padding()
        .background(Color("backgroundApp").edgesIgnoringSafeArea(.all)) // Fondo desde los assets
        .cornerRadius(30) // Bordes redondeados para el contenedor
        .shadow(radius: 10) // Sombra para la vista principal
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
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

