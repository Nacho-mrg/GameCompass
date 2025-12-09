import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FavoriteGamesView: View {
    
    @State private var favoriteGames: [Game]
    @State private var isLoading: Bool
    @State private var loadError: Error?
    @State private var favoritesListener: ListenerRegistration? = nil

    // Inicializador principal (para la aplicación en ejecución)
    init() {
        _favoriteGames = State(initialValue: [])
        _isLoading = State(initialValue: true)
        _loadError = State(initialValue: nil)
    }

    // Inicializador de conveniencia (para el Canvas/Previews)
    internal init(favoriteGames: [Game], isLoading: Bool, loadError: Error? = nil) {
        _favoriteGames = State(initialValue: favoriteGames)
        _isLoading = State(initialValue: isLoading)
        _loadError = State(initialValue: loadError)
    }

    // Propiedad que verifica si debemos mostrar la vista de "Vacío" o "No Logueado".
    private var shouldShowEmptyView: Bool {
        
        let isPermissionError = (loadError as? NSError)?.code == 7
        
        return !isLoading && favoriteGames.isEmpty && (loadError == nil || isPermissionError)
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .background(
                    LinearGradient(colors: [Color("backgroundApp"), Color("backgroundComponent").opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .ignoresSafeArea(.container, edges: .all)

            VStack(spacing: 20) {
                // Encabezado
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.pink)
                            .frame(width: 28, height: 28)
                            .symbolEffect(.pulse, options: .repeating)
                        Text("Tus Favoritos")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                    }
                    Text("Los juegos que más te inspiran")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 24)

                // Contenido
                Group {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.6)
                            Text("Cargando tus favoritos...")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color("backgroundComponent").opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                        .padding(.horizontal)
                    } else if shouldShowEmptyView {
                        // Muestra la vista de "Vacío" (Incluye estado sin usuario o error de permisos)
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 52))
                                .foregroundColor(.white.opacity(0.9))
                                .symbolEffect(.bounce, options: .repeating)
                            Text("No tienes juegos favoritos")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            Text("Explora el catálogo y añade algunos para verlos aquí.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.callout)
                            
                            Button {
                                // Acción para navegar a explorar si tienes router
                            } label: {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                    Text("Descubrir juegos")
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.pink.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: .pink.opacity(0.4), radius: 10, y: 6)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color("backgroundComponent").opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
                        .padding(.horizontal)
                    } else if loadError != nil {
                        // Muestra la vista de ERROR solo para otros errores (ej. red)
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.red)
                            Text("Error al cargar favoritos")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Ocurrió un error inesperado. Inténtalo de nuevo.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.callout)
                            
                            // Muestra el mensaje de error para debug
                            Text(loadError!.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color("backgroundComponent").opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
                        .padding(.horizontal)
                    } else { // favoriteGames no es vacío
                        // Muestra la lista de juegos
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(favoriteGames) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        GameCardDecorated(game: game)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                        .contentMargins(.horizontal, 0)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .onAppear { startFavoritesListener() }
        .onDisappear { stopFavoritesListener() }
        .task { await loadFavoriteGames() }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Firestore Listener para favoritos
    private func startFavoritesListener() {
        stopFavoritesListener()
        // Si no hay usuario, salimos al estado vacío.
        guard let user = Auth.auth().currentUser else {
            self.loadError = nil
            self.favoriteGames = []
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        isLoading = true
        favoritesListener = db.collection("users").document(user.uid).addSnapshotListener { snapshot, error in
            if let error = error {
                self.loadError = error
                self.favoriteGames = []
                self.isLoading = false
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                self.favoriteGames = []
                self.isLoading = false
                return
            }
            
            let favoriteIDsInt: [Int]
            if let ints = data["favoriteIDs"] as? [Int] {
                favoriteIDsInt = ints
            } else if let strings = data["favoriteIDs"] as? [String] {
                favoriteIDsInt = strings.compactMap { Int($0) }
            } else {
                favoriteIDsInt = []
            }
            Task { await self.refreshGames(for: favoriteIDsInt) }
        }
    }

    private func stopFavoritesListener() {
        favoritesListener?.remove()
        favoritesListener = nil
    }

    // Carga los juegos desde tu API dado un array de IDs en Int
    private func refreshGames(for favoriteIDs: [Int]) async {
        if favoriteIDs.isEmpty {
            await MainActor.run {
                self.favoriteGames = []
                self.isLoading = false
                self.loadError = nil
            }
            return
        }
        await MainActor.run { self.isLoading = true; self.loadError = nil }
        let intIDs: [Int] = favoriteIDs
        do {
            let games = try await loadGamesViaAPI(ids: intIDs)
            await MainActor.run {
                self.favoriteGames = games
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.favoriteGames = []
                self.isLoading = false
                self.loadError = error
            }
        }
    }

    // MARK: - FUNCIÓN DE CARGA INICIAL (Solo verifica Auth y lanza el listener)
    private func loadFavoriteGames() async {
        await MainActor.run {
            self.loadError = nil
            self.isLoading = true
        }
        
        if favoritesListener != nil { return }
        
        // Si no hay usuario, establecemos el estado final sin error para que shouldShowEmptyView lo maneje.
        guard Auth.auth().currentUser != nil else {
            await MainActor.run {
                self.favoriteGames = []
                self.isLoading = false
                self.loadError = nil
            }
            return
        }
        
        // Si hay usuario, iniciamos el listener.
        startFavoritesListener()
    }

    // MARK: - Helpers para escribir favoritos (guardar como enteros)
    private func addFavorite(id: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(uid).updateData([
                "favoriteIDs": FieldValue.arrayUnion([id])
            ])
        } catch {
            await MainActor.run { self.loadError = error }
        }
    }

    private func removeFavorite(id: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(uid).updateData([
                "favoriteIDs": FieldValue.arrayRemove([id])
            ])
        } catch {
            await MainActor.run { self.loadError = error }
        }
    }

    // MARK: - Lógica real de API (RAWG)
    private func loadGamesViaAPI(ids: [Int]) async throws -> [Game] {
        // Reutiliza la misma API key que usas en GameDetailViewModel
        let apiKey = "b9355a95d4084728bb4486202b0a231e"
        let session = URLSession.shared

        struct RAWGGame: Decodable {
            let id: Int
            let name: String
            let background_image: String?
        }

        func url(for id: Int) -> URL? {
            URL(string: "https://api.rawg.io/api/games/\(id)?key=\(apiKey)")
        }

        // Ejecuta solicitudes en paralelo y filtra las que fallen
        var results: [Game] = []
        results.reserveCapacity(ids.count)

        try await withThrowingTaskGroup(of: Game?.self) { group in
            for id in ids {
                group.addTask {
                    guard let url = url(for: id) else { return nil }
                    let (data, response) = try await session.data(from: url)
                    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                        return nil
                    }
                    let decoded = try JSONDecoder().decode(RAWGGame.self, from: data)
                    return Game(
                        id: decoded.id,
                        name: decoded.name,
                        backgroundImage: decoded.background_image ?? ""
                    )
                }
            }

            for try await maybeGame in group {
                if let game = maybeGame { results.append(game) }
            }
        }

        // Ordena por el orden de entrada para mantener consistencia visual
        let order: [Int: Int] = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
        let ordered = results.sorted { (lhs, rhs) in
            (order[lhs.id] ?? Int.max) < (order[rhs.id] ?? Int.max)
        }
        return ordered
    }
}

// MARK: - COMPONENTES DE VISTA Y PREVIEWS

struct GameCardDecorated: View {
    let game: Game

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = URL(string: game.backgroundImage) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                } placeholder: {
                    ZStack {
                        Color(UIColor(named: "backgroundComponent") ?? .gray).opacity(0.6)
                        ProgressView().tint(.white)
                    }
                    .frame(height: 180)
                }
            } else {
                ZStack(alignment: .bottomLeading) {
                    Color(UIColor(named: "backgroundComponent") ?? .gray).opacity(0.6)
                        .frame(height: 180)
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                .frame(height: 180)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").foregroundColor(.pink)
                    Text("Favorito")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor(named: "backgroundComponent") ?? .gray).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
    }
}

// MARK: - PREVIEW DATA
private struct FavoriteGamesPreviewData {
    // Definición de datos de prueba para la previsualización
    static let sampleGames: [Game] = [
        Game(id: 101, name: "The Legend of Zelda", backgroundImage: "https://picsum.photos/id/400/800/400"),
        Game(id: 102, name: "Super Mario Odyssey", backgroundImage: "https://picsum.photos/id/500/800/400")
    ]
}

#Preview {
    NavigationView {
        FavoriteGamesView(favoriteGames: FavoriteGamesPreviewData.sampleGames, isLoading: false)
    }
    .previewDisplayName("✅ Con Juegos")
}

#Preview {
    NavigationView {
        // Previsualiza el estado de no logueado / error de permisos
        FavoriteGamesView(favoriteGames: [], isLoading: false)
    }
    .previewDisplayName("❌ Vacío / No Logueado")
}
