import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

struct UserProfileView: View {
    @State private var user: User? = Auth.auth().currentUser
    @State private var showLogoutAlert = false
    @State private var showLoginFullScreen = false
    @State private var showSuccessAlert = false
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showPhotoPicker = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), .black.opacity(0.9)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Imagen de perfil
                if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(color: Color("ButtonColor").opacity(0.5), radius: 8, x: 0, y: 4)
                } else if let photoURL = user?.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("ButtonColor")))
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(color: Color("ButtonColor").opacity(0.5), radius: 8, x: 0, y: 4)
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray.opacity(0.8))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                // Botón cambiar foto
                Button(action: { showPhotoPicker = true }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Cambiar foto")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(12)
                }
                .photosPicker(isPresented: $showPhotoPicker,
                              selection: $selectedItem,
                              matching: .images,
                              photoLibrary: .shared())
                .onChange(of: selectedItem) { newItem in
                    if let newItem {
                        newItem.loadTransferable(type: Data.self) { result in
                            switch result {
                            case .success(let data):
                                if let data {
                                    selectedImageData = data
                                }
                            case .failure(let error):
                                print("Error al cargar la imagen: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Botón guardar
                if selectedImageData != nil {
                    Button(action: { saveProfileImage() }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Guardar")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .alert("¡Éxito!", isPresented: $showSuccessAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Tu foto de perfil se ha guardado correctamente.")
                    }
                }
                
                // Nombre y email
                Text(user?.displayName ?? "Usuario sin nombre")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(user?.email ?? "Correo no disponible")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Divider()
                    .frame(width: 180)
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 10)
                
                // Cerrar sesión
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.top, 10)
                .alert("Cerrar sesión", isPresented: $showLogoutAlert) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Cerrar sesión", role: .destructive) {
                        signOutUser()
                    }
                } message: {
                    Text("¿Seguro que deseas cerrar sesión?")
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Perfil de Usuario")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showLoginFullScreen) {
            LoginView()
        }
    }
    
    func signOutUser() {
        do {
            try Auth.auth().signOut()
            showLoginFullScreen = true
        } catch let error {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
    
    func saveProfileImage() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No hay usuario logueado")
            return
        }
        guard let data = selectedImageData else { return }
        
        let uid = currentUser.uid
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("Error subiendo imagen: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error obteniendo URL: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else { return }
                
                // 🔹 Guardar en Firestore igual que en MenuView
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "uid": uid,
                    "displayName": currentUser.displayName ?? "",
                    "email": currentUser.email ?? "",
                    "photoURL": url.absoluteString
                ]
                
                db.collection("users").document(uid).setData(userData, merge: true) { error in
                    if let error = error {
                        print("❌ Error guardando en Firestore: \(error.localizedDescription)")
                    } else {
                        print("✅ Datos del usuario guardados correctamente en Firestore")
                        // Actualizar Auth user.photoURL
                        let changeRequest = currentUser.createProfileChangeRequest()
                        changeRequest.photoURL = url
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error actualizando Auth user.photoURL: \(error.localizedDescription)")
                            } else {
                                self.user = Auth.auth().currentUser
                                self.showSuccessAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}

