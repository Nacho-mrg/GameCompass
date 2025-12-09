import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - Contenedor Principal de la Aplicación (TabView)

struct ContentView: View {
    @State private var selectedTab: Int = 0
    private let tabImpact = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        // TabView: Contenedor principal para la navegación por pestañas
        TabView(selection: $selectedTab) {
            // Pestaña 1: Buscador/Menú Principal
            NavigationView {
                MenuView()
            }
            .tabItem {
                Label("Buscador", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Pestaña 2: Noticias
            NoticiasView()
                .tabItem {
                    Label("Noticias", systemImage: "newspaper")
                }
                .tag(1)

            // Pestaña 3: Patchnotes de Steam
            NavigationView {
                SteamPatchNotesView()
            }
            .tabItem {
                Label("Patchnotes", systemImage: "doc.text.fill")
            }
            .tag(2)

            // Pestaña 4: Plan de Pago
            PlanPagoView()
                .tabItem {
                    Label("Plan de Pago", systemImage: "creditcard.fill")
                }
                .tag(3)

            // Pestaña 5: Recomendador
            RecomendadorView()
                .tabItem {
                    Label("Recomendador", systemImage: "sparkles")
                }
                .tag(4)
        }
        // Color de acento aplicado a los íconos de la TabView
        .accentColor(Color("ButtonColor"))
        .onChange(of: selectedTab) { _, _ in
            tabImpact.prepare()
            tabImpact.impactOccurred()
        }
    }
}


// ---

// MARK: - Vista Principal del Menú (Buscador)

struct MenuView: View {
    
    
    // MARK: Propiedades de Estado y Entorno
    
    @StateObject private var viewModel = GameViewModel() // ViewModel para la lógica de juegos
    @State private var searchText: String = ""
    @State private var showingLogin = false
    @State private var showDropdown = false // Estado para el menú desplegable
    @State private var favorites: [Game] = [] // Lista local de juegos favoritos
    @State private var navigateToFavorites = false
    @State private var navigateToProfile = false
    
    // Firebase
    private let db = Firestore.firestore()
    @State private var userUID: String? = Auth.auth().currentUser?.uid

    // Animación y Foco
    @State private var isSearching = false // Estado para cambiar el estilo de la barra de búsqueda
    @FocusState private var searchFieldFocused: Bool
    @State private var animateHeader = false // Estado para la animación inicial del header
    @State private var floatingBubbles: [CGFloat] = [0.1, 0.35, 0.6, 0.85] // Posiciones para las "burbujas" de fondo

    // MARK: Propiedad Calculada
    
    // Juegos filtrados basados en la barra de búsqueda
    var filteredGames: [Game] {
        if searchText.isEmpty {
            return viewModel.games
        } else {
            return viewModel.games.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    // MARK: Cuerpo de la Vista
    
    var body: some View {
        ZStack {
            // Fondo animado y con gradientes
            backgroundView
            
            VStack(spacing: 0) {
                // Cabecera con título, logo y botón de menú
                header
                    .padding(.horizontal)
                    .padding(.top, 8)
                    // Decoración del fondo de la cabecera
                    .background(headerBackground)
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)

                // Barra de búsqueda con estilo personalizado
                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                // Lista de juegos
                gameListScrollView

                Spacer(minLength: 10)
            }
            .background(Color("backgroundApp")) // Fondo principal
            .navigationBarHidden(true) // Oculta la NavigationBar por defecto
            
            // Presentación modal para la vista de Login
            .fullScreenCover(isPresented: $showingLogin) {
                LoginView()
            }

            // Enlaces de navegación inactivos, se activan con las variables de estado
            .background(navigationLinks)
        }
        .onAppear {
            // Carga inicial de datos y animación
            viewModel.fetchGames()
            self.userUID = Auth.auth().currentUser?.uid
            loadFavorites()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { animateHeader = true } // Inicia la animación del header y las burbujas
            }
        }
    }
    
    // MARK: - Funciones de Lógica
    
    // Carga los IDs de favoritos del usuario desde Firestore y los mapea a objetos Game
    private func loadFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.favorites = []
            return
        }
        let userDocRef = db.collection("users").document(uid)
        
        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error obteniendo favoritos: \(error.localizedDescription)")
                return
            }
            
            let data = snapshot?.data() ?? [:]
            let ids = data["favoriteIDs"] as? [Int] ?? []
            
            // Mapea los IDs a juegos conocidos o crea un placeholder si aún no se han cargado los juegos completos
            let mapped: [Game] = ids.compactMap { id in
                if let game = self.viewModel.games.first(where: { $0.id == id }) {
                    return game
                } else {
                    // Placeholder si el juego no está en la lista principal todavía (se actualizará al cargar)
                    return Game(id: id, name: "Cargando...", backgroundImage: "")
                }
            }
            self.favorites = mapped
        }
    }

    // Cierra la sesión del usuario en Firebase
    func signOutUser() {
        do {
            try Auth.auth().signOut()
            // Limpieza de datos locales
            UserDefaults.standard.removeObject(forKey: "userUID")
            UserDefaults.standard.synchronize()
            favorites.removeAll()
            searchText = ""
            userUID = nil
        } catch let signOutError as NSError {
            print("Error al cerrar sesión: \(signOutError)")
        }
    }
    
    // MARK: - Subvistas Estilizadas

    // 1. Vista de Fondo con Gradientes y Animación de Burbujas
    private var backgroundView: some View {
        LinearGradient(colors: [Color("backgroundApp"), Color("backgroundApp").opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea(edges: .top)
            // Gradiente angular sutil
            .overlay(
                AngularGradient(gradient: Gradient(colors: [Color("ButtonColor").opacity(0.12), .clear, Color("ButtonColor").opacity(0.08), .clear]), center: .topLeading)
                    .ignoresSafeArea()
                    .blendMode(.plusLighter) // Efecto de luz
            )
            // Burbujas animadas
            .overlay(
                ZStack {
                    ForEach(Array(floatingBubbles.enumerated()), id: \.offset) { idx, xPos in
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 180, height: 180)
                            .blur(radius: 12)
                            // Desplazamiento animado
                            .offset(x: (UIScreen.main.bounds.width * (xPos - 0.5)), y: animateHeader ? -220 : -260)
                            .animation(
                                .easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(idx) * 0.2),
                                value: animateHeader
                            )
                    }
                }
            )
    }

    // 2. Fondo de la Cabecera
    private var headerBackground: some View {
        ZStack {
            // Efecto de cristal con color
            LinearGradient(colors: [Color("ButtonColor").opacity(0.85), Color("ButtonColor").opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
                .overlay(.ultraThinMaterial.opacity(0.08)) // Material translúcido
            
            // Separador inferior
            Divider().background(Color.white.opacity(0.06)).offset(y: 52)
        }
        .overlay(
            // Borde superior brillante
            LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 1)
                .offset(y: 0)
        )
    }
    
    // 3. Cabecera (Logo, Título y Botón de Menú)
    private var header: some View {
        HStack(spacing: 15) {
            // Logo animado
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                // Animación de rotación 3D al aparecer
                .rotation3DEffect(.degrees(animateHeader ? 0 : 6), axis: (x: 0.0, y: 1.0, z: 0.0))
                .animation(.spring(response: 0.9, dampingFraction: 0.7, blendDuration: 0.4), value: animateHeader)

            // Texto de la aplicación
            VStack(alignment: .leading, spacing: 2) {
                Text("GameHub")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Explora y guarda tus favoritos")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
             

            Spacer()

            // Botón de Menú Desplegable (Dropdown)
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showDropdown.toggle() }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color("ButtonColor").opacity(0.95))
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            // Menú desplegable superpuesto
            .overlay(
                dropdownMenu
                    .opacity(showDropdown ? 1 : 0)
                    .offset(y: showDropdown ? 8 : -25) // Animación de desplazamiento
                    .animation(.easeInOut(duration: 0.2), value: showDropdown)
                    .allowsHitTesting(showDropdown)
            )
        }
    }

    // 4. Menú Desplegable
    private var dropdownMenu: some View {
        VStack(spacing: 0) {
            // Botón de Perfil
            Button(action: { navigateToProfile = true; withAnimation { showDropdown = false } }) {
                Label("Perfil", systemImage: "person.crop.circle")
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.white.opacity(0.04))

            Divider().background(Color.white.opacity(0.15))

            // Botón de Favoritos
            Button(action: { navigateToFavorites = true; withAnimation { showDropdown = false } }) {
                Label("Ver favoritos", systemImage: "star.fill")
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        // Estilo del menú (Gradiente, borde y sombra)
        .background(
            LinearGradient(colors: [Color("ButtonColor"), Color("ButtonColor").opacity(0.85)], startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        .frame(width: 200)
        .padding(.trailing, 10)
        .offset(x: -20, y: 50)
        .zIndex(1) // Asegura que esté por encima de otros elementos
    }

    // 5. Barra de Búsqueda
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                // Cambia de color cuando se está editando
                .foregroundColor(isSearching ? Color("ButtonColor") : Color.white.opacity(0.65))
            
            TextField("Buscar juegos", text: $searchText, onEditingChanged: { editing in
                withAnimation(.easeInOut(duration: 0.2)) { isSearching = editing }
            })
            .focused($searchFieldFocused)
            .foregroundColor(.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)

            // Botón para limpiar el texto
            if !searchText.isEmpty {
                Button(action: { withAnimation { searchText = "" } }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        // Estilo de cápsula con fondo y borde dinámico
        .background(
            Capsule(style: .continuous)
                .fill(Color("backgroundComponent").opacity(0.95))
                .overlay(
                    Capsule().strokeBorder(isSearching ? Color("ButtonColor").opacity(0.6) : .white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 3)
    }
    
    // 6. ScrollView de la Lista de Juegos
    private var gameListScrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 18) {
                ForEach(filteredGames) { game in
                    // Enlace a la vista de detalle
                    NavigationLink(destination: GameDetailView(game: game)) {
                        GameCard(game: game, favorites: $favorites)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle()) // Evita el estilo de botón por defecto de NavLink
                }
            }
            .padding(.vertical)
        }
    }
    
    // 7. Contenedor de NavigationLinks
    private var navigationLinks: some View {
        Group {
            NavigationLink(
                destination: FavoriteGamesView(),
                isActive: $navigateToFavorites,
                label: { EmptyView() }
            )
            NavigationLink(
                destination: UserProfileView(),
                isActive: $navigateToProfile,
                label: { EmptyView() }
            )
        }
    }
}

// ---

// MARK: - Tarjeta de Juego (GameCard)

struct GameCard: View {
    
    // MARK: Propiedades y Entorno
    
    var game: Game
    @Binding var favorites: [Game] // Binding para actualizar el estado de favoritos en MenuView
    
    private let db = Firestore.firestore()
    private var userUID: String? { Auth.auth().currentUser?.uid }
    
    // Propiedad calculada para verificar el estado de favorito
    var isFavorite: Bool {
        favorites.contains(where: { $0.id == game.id })
    }

    // MARK: Cuerpo de la Vista
    
    var body: some View {
        HStack(spacing: 14) {
            // Imagen del juego (Carga asíncrona)
            gameImage
            
            // Nombre y ID
            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                
                Text("ID: \(game.id)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()

            // Botón de Favorito
            favoriteButton
        }
        .padding()
        // Fondo estilizado
        .background(Color("backgroundComponent"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.28), radius: 7, x: 0, y: 5)
        .scaleEffect(0.999) // Pequeña corrección visual
        // Animación al cambiar el estado de favorito
        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: isFavorite)
    }
    
    // MARK: - Funciones de Lógica
    
    // Lógica para alternar el estado de favorito en la vista local y en Firestore
    private func toggleFavorite() {
        guard let uid = userUID else {
            print("No hay usuario autenticado. No se puede modificar favoritos.")
            return
        }
        let userDocRef = db.collection("users").document(uid)

        if let index = favorites.firstIndex(where: { $0.id == game.id }) {
            // 1. Eliminar (Desmarcar favorito)
            favorites.remove(at: index) // Actualización local inmediata
            userDocRef.setData([
                "favoriteIDs": FieldValue.arrayRemove([game.id])
            ], merge: true) { error in
                if let error = error {
                    print("Error eliminando id de favoritos (users/\(uid)): \(error.localizedDescription)")
                } else {
                    print("Id \(game.id) eliminado de favoriteIDs en users/\(uid)")
                }
            }
        } else {
            // 2. Agregar (Marcar favorito)
            favorites.append(game) // Actualización local inmediata
            
            // Asegurar que el documento del usuario exista y luego agregar el ID
            userDocRef.setData(["uid": uid], merge: true) { parentErr in
                if let parentErr = parentErr {
                    print("No se pudo asegurar users/\(uid): \(parentErr.localizedDescription)")
                }
                userDocRef.setData([
                    "favoriteIDs": FieldValue.arrayUnion([self.game.id])
                ], merge: true) { error in
                    if let error = error {
                        print("Error agregando id a favoritos (users/\(uid)): \(error.localizedDescription)")
                    } else {
                        print("Id \(self.game.id) agregado a favoriteIDs en users/\(uid)")
                    }
                }
            }
        }
    }
    
    // MARK: - Subvistas Estilizadas
    
    // 1. Imagen del Juego (AsyncImage)
    private var gameImage: some View {
        AsyncImage(url: URL(string: game.backgroundImage)) { phase in
            switch phase {
            case .empty:
                // Estado de carga
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color("ButtonColor"))).frame(width: 100, height: 100)
            case .success(let image):
                // Carga exitosa
                image.resizable().scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            case .failure(_):
                // Error de carga
                Image(systemName: "photo").resizable().scaledToFit().frame(width: 100, height: 100).foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    // 2. Botón de Favorito
    private var favoriteButton: some View {
        Button { toggleFavorite() } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title2)
                .foregroundColor(isFavorite ? .yellow : .gray)
                .padding(10)
                // Fondo semi-transparente que cambia con el estado
                .background(Color.white.opacity(isFavorite ? 0.15 : 0.05))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ---

// MARK: - Modelo de Datos

struct Game: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let backgroundImage: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case backgroundImage = "background_image"
    }
}

// ---

// MARK: - Previsualización

#Preview {
    ContentView()
}

