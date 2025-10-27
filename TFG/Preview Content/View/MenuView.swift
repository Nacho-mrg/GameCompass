import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                MenuView()
            }
            .tabItem {
                Label("Buscador", systemImage: "list.bullet")
            }
            
            NoticiasView()
                .tabItem {
                    Label("Noticias", systemImage: "newspaper")
                }

            NavigationView {
                SteamPatchNotesView()
            }
            .tabItem {
                Label("Patchnotes", systemImage: "doc.text.fill")
            }

            PlanPagoView()
                .tabItem {
                    Label("Plan de Pago", systemImage: "creditcard.fill")
                }

            RecomendadorView()
                .tabItem {
                    Label("Recomendador", systemImage: "sparkles")
                }
        }
        .accentColor(Color("ButtonColor"))
    }
}

struct MenuView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var searchText: String = ""
    @State private var showingLogin = false
    @State private var showDropdown = false
    @State private var favorites: [Game] = []
    @State private var navigateToFavorites = false
    @State private var navigateToNoticias = false
    @State private var navigateToProfile = false

    var filteredGames: [Game] {
        if searchText.isEmpty {
            return viewModel.games
        } else {
            return viewModel.games.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                header.padding(.horizontal).padding(.top, 8)
                    .background(
                        LinearGradient(
                            colors: [Color("ButtonColor").opacity(0.9), Color("ButtonColor").opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                        .ignoresSafeArea(edges: .top)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)

                searchBar.padding(.horizontal).padding(.vertical, 10)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        ForEach(filteredGames) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                GameCard(game: game, favorites: $favorites)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                }

                Spacer(minLength: 10)
            }
            .background(Color("backgroundApp"))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingLogin) {
                LoginView()
            }

            // Navegaciones existentes
            .background(
                NavigationLink(
                    destination: FavoritesView(favorites: favorites),
                    isActive: $navigateToFavorites,
                    label: { EmptyView() }
                )
            )
            .background(
                NavigationLink(
                    destination: UserProfileView(),
                    isActive: $navigateToProfile,
                    label: { EmptyView() }
                )
            )
        }
        .onAppear {
            viewModel.fetchGames()
        }
    }

    private var header: some View {
        HStack(spacing: 15) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 55, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 3)

            Spacer()

            Button(action: { withAnimation { showDropdown.toggle() } }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color("ButtonColor"))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .overlay(
                dropdownMenu.opacity(showDropdown ? 1 : 0)
                    .offset(y: showDropdown ? 8 : -25)
                    .animation(.easeInOut(duration: 0.2), value: showDropdown)
                    .allowsHitTesting(showDropdown)
            )
        }
    }

    private var dropdownMenu: some View {
        VStack(spacing: 0) {
            Button(action: { navigateToProfile = true; withAnimation { showDropdown = false } }) {
                Label("Perfil", systemImage: "person.crop.circle")
                    .foregroundColor(.white).padding(.vertical, 12).frame(maxWidth: .infinity)
            }
            Divider().background(Color.white.opacity(0.3))
            Button(action: { navigateToFavorites = true; withAnimation { showDropdown = false } }) {
                Label("Ver favoritos", systemImage: "star.fill")
                    .foregroundColor(.white).padding(.vertical, 12).frame(maxWidth: .infinity)
            }
            Divider().background(Color.white.opacity(0.3))
            Divider().background(Color.white.opacity(0.3))
            Button(action: { signOutUser(); showingLogin = true; withAnimation { showDropdown = false } }) {
                Label("Cerrar sesión", systemImage: "power")
                    .foregroundColor(.white).padding(.vertical, 12).frame(maxWidth: .infinity)
            }
        }
        .background(Color("ButtonColor"))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        .frame(width: 180)
        .padding(.trailing, 10)
        .offset(x: -20, y: 50)
        .zIndex(1)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(Color.white.opacity(0.65))
            TextField("Buscar juegos", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(14)
        .background(Color("backgroundComponent"))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 3)
    }

    func signOutUser() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "userUID")
            UserDefaults.standard.synchronize()
            favorites.removeAll()
            searchText = ""
        } catch let signOutError as NSError {
            print("Error al cerrar sesión: %@", signOutError)
        }
    }
}

struct GameCard: View {
    var game: Game
    @Binding var favorites: [Game]

    private let db = Firestore.firestore()
    private let userUID = Auth.auth().currentUser?.uid

    var isFavorite: Bool {
        favorites.contains(where: { $0.id == game.id })
    }

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: game.backgroundImage)) { phase in
                switch phase {
                case .empty:
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color("ButtonColor"))).frame(width: 100, height: 100)
                case .success(let image):
                    image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                case .failure(_):
                    Image(systemName: "photo").resizable().scaledToFit().frame(width: 100, height: 100).foregroundColor(.gray)
                @unknown default: EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(game.name).font(.headline).foregroundColor(.white).lineLimit(2).minimumScaleFactor(0.75)
                Text("ID: \(game.id)").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Spacer()

            Button { toggleFavorite() } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .padding(10)
                    .background(Color.white.opacity(isFavorite ? 0.15 : 0.05))
                    .clipShape(Circle())
            }.buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color("backgroundComponent"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.28), radius: 7, x: 0, y: 5)
    }

    private func toggleFavorite() {
        guard let uid = userUID else { return }
        let userFavoritesRef = db.collection("users").document(uid).collection("favorites")

        if let index = favorites.firstIndex(where: { $0.id == game.id }) {
            favorites.remove(at: index)
            userFavoritesRef.document("\(game.id)").delete { error in
                if let error = error { print("Error eliminando favorito: \(error)") }
            }
        } else {
            favorites.append(game)
            let data: [String: Any] = ["gameID": game.id, "name": game.name, "backgroundImage": game.backgroundImage]
            userFavoritesRef.document("\(game.id)").setData(data) { error in
                if let error = error { print("Error guardando favorito: \(error)") }
            }
        }
    }
}

struct Game: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let backgroundImage: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case backgroundImage = "background_image"
    }
}

#Preview {
    ContentView()
}

