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
            LinearGradient(gradient: Gradient(colors: [
                Color("backgroundApp"),
                .black.opacity(0.9)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                // FOTO DE PERFIL
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .shadow(color: Color("ButtonColor").opacity(0.4), radius: 10)
                    
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } else if let url = user?.photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty: ProgressView()
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable().scaledToFit()
                            @unknown default: EmptyView()
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 20)
                
                // BOTÓN CAMBIAR FOTO
                Button(action: { showPhotoPicker = true }) {
                    Text("Cambiar foto")
                        .font(.subheadline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3)))
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    newItem?.loadTransferable(type: Data.self) { result in
                        if case .success(let data?) = result { selectedImageData = data }
                    }
                }
                
                // BOTÓN GUARDAR
                if selectedImageData != nil {
                    Button(action: saveProfileImage) {
                        Text("Guardar foto")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.green.opacity(0.8), .green], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                            .shadow(color: .green.opacity(0.5), radius: 8)
                    }
                    .padding(.horizontal)
                    .alert("¡Éxito!", isPresented: $showSuccessAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Tu foto de perfil se ha guardado correctamente.")
                    }
                }
                
                // TARJETA DE DATOS
                VStack(spacing: 6) {
                    Text(user?.displayName ?? "Usuario sin nombre")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text(user?.email ?? "")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                
                Spacer()
                
                // BOTÓN CERRAR SESIÓN
                Button(action: { showLogoutAlert = true }) {
                    Text("Cerrar sesión")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.red.opacity(0.85), .red], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                        .shadow(color: .red.opacity(0.6), radius: 8)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .alert("Cerrar sesión", isPresented: $showLogoutAlert) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Cerrar sesión", role: .destructive) { signOutUser() }
                } message: {
                    Text("¿Seguro que deseas cerrar sesión?")
                }
            }
        }
        .fullScreenCover(isPresented: $showLoginFullScreen) {
            LoginView()
        }
    }
    
    func signOutUser() {
        try? Auth.auth().signOut()
        showLoginFullScreen = true
    }
    
    func saveProfileImage() {
        guard let user = Auth.auth().currentUser,
              let data = selectedImageData else { return }
        
        let ref = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        ref.putData(data, metadata: metadata) { _, _ in
            ref.downloadURL { url, _ in
                guard let url else { return }
                
                Firestore.firestore().collection("users")
                    .document(user.uid)
                    .setData(["photoURL": url.absoluteString], merge: true)
                
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = url
                changeRequest.commitChanges { _ in
                    self.user = Auth.auth().currentUser
                    showSuccessAlert = true
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}

