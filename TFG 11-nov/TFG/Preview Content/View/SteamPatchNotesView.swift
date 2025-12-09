import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - 1. Modelos de Datos

struct AppListResponse: Codable {
    let applist: Applist
    struct Applist: Codable {
        let apps: [SteamApp]
    }
}

struct SteamApp: Codable, Identifiable, Hashable {
    let appid: Int
    var name: String
    var id: Int { appid }
}

struct NewsResponse: Codable {
    let appnews: AppNews
    struct AppNews: Codable {
        let appid: Int
        let newsitems: [NewsItem]
    }
}

struct NewsItem: Codable, Identifiable {
    let gid: String
    let title: String
    let url: String
    // Eliminamos 'is_external_url' y 'author' ya que no son usados en el View
    let contents: String
    let date: TimeInterval
    var id: String { gid }
    var dateFormatted: String {
        let d = Date(timeIntervalSince1970: date)
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}

// Modelo que mapea el documento 'users' (solo necesitamos el array de IDs)
struct UserDocument: Codable {
    @DocumentID var id: String?
    let favoriteIds: [Int]? // Campo clave que almacena los AppIDs de Steam
    // Eliminamos los demás campos por simplicidad, aunque existen en Firestore
}

// MARK: - 2. Steam API Cliente (Lógica de red real)

final class SteamAPI {
    static let shared = SteamAPI()
    private init() {}
    private let session = URLSession.shared
    private var cachedAppList: [SteamApp]?

    func fetchAppListIfNeeded() async throws -> [SteamApp] {
        if let cached = cachedAppList { return cached }
        
        let url = URL(string: "https://api.steampowered.com/ISteamApps/GetAppList/v2/")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        
        let decoded = try JSONDecoder().decode(AppListResponse.self, from: data)
        let apps = decoded.applist.apps.filter { $0.appid > 0 && !$0.name.isEmpty }
        cachedAppList = apps
        return apps
    }

    func searchApps(query: String = "", limit: Int = 50) async throws -> [SteamApp] {
        let all = try await fetchAppListIfNeeded()
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             return Array(all.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }).prefix(limit))
        }
        
        let lowered = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let filtered = all.filter { $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(lowered) }
            .prefix(limit)
            .map { $0 }
            
        return filtered
    }
    
    // Función CLAVE: Convierte IDs de Firebase en objetos SteamApp
    func fetchApps(by appIDs: [Int]) async throws -> [SteamApp] {
        let all = try await fetchAppListIfNeeded()
        let apps = all.filter { appIDs.contains($0.appid) }
        return apps.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }

    func fetchNewsForApp(appid: Int, count: Int = 10, maxlength: Int = 10000) async throws -> [NewsItem] {
        var components = URLComponents(string: "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/")!
        components.queryItems = [
            URLQueryItem(name: "appid", value: String(appid)),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "maxlength", value: String(maxlength))
        ]
        
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        
        let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
        return decoded.appnews.newsitems
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - 2.1 RAWG API Cliente (para nombres de favoritos)

struct RAWGGameSearchResponse: Codable {
    let results: [RAWGGame]
}

struct RAWGGame: Codable {
    let id: Int
    let name: String
    let slug: String?
}

final class RAWGAPI {
    static let shared = RAWGAPI()
    private init() {}
    private let session = URLSession.shared
    // Si tienes API key, colócala aquí. RAWG permite sin key con límites.
    private let baseURL = URL(string: "https://api.rawg.io/api")!
    private let apiKey: String? = nil // Coloca tu key si la tienes

    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        var items = queryItems
        if let apiKey = apiKey, !apiKey.isEmpty {
            items.append(URLQueryItem(name: "key", value: apiKey))
        }
        components?.queryItems = items
        return components?.url
    }

    // Intenta resolver por appid usando búsqueda por consulta "steam appid:<id>" y, si falla, por nombre.
    func resolveNameForSteamApp(appid: Int, fallbackName: String?) async throws -> String? {
        // 1) Intento por consulta con appid en texto (RAWG no expone endpoint oficial por appid Steam, pero muchas entradas incluyen el appid en metadatos)
        if let url = makeURL(path: "games", queryItems: [URLQueryItem(name: "search", value: "steam appid:\(appid)"), URLQueryItem(name: "page_size", value: "1")]) {
            if let name = try await firstResultName(from: url) { return name }
        }
        // 2) Intento por nombre de fallback si existe
        if let fallback = fallbackName, !fallback.isEmpty,
           let url = makeURL(path: "games", queryItems: [URLQueryItem(name: "search", value: fallback), URLQueryItem(name: "page_size", value: "1")]) {
            if let name = try await firstResultName(from: url) { return name }
        }
        return nil
    }

    private func firstResultName(from url: URL) async throws -> String? {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        let decoded = try? JSONDecoder().decode(RAWGGameSearchResponse.self, from: data)
        return decoded?.results.first?.name
    }
}

// MARK: - 3. Firestore Service (Lógica de BBDD real)

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // 🔑 Obtiene el array de enteros [3498, 3328, 4200]
    func fetchFavoriteAppIDs() async throws -> [Int] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])
        }

        let documentRef = db.collection("users").document(userId)

        let snapshot: DocumentSnapshot
        do {
            snapshot = try await documentRef.getDocument()
        } catch {
            print("Error al obtener el documento: \(error.localizedDescription)")
            throw error
        }

        guard snapshot.exists else {
            // Documento no existe aún
            return []
        }

        let data = snapshot.data() ?? [:]
        let raw = data["favoriteIds"]

        // Coerción robusta de tipos posibles devueltos por Firestore
        if let ints = raw as? [Int] {
            return ints
        }
        if let numbers = raw as? [NSNumber] {
            return numbers.map { $0.intValue }
        }
        if let strings = raw as? [String] {
            return strings.compactMap { Int($0) }
        }
        if let anyArray = raw as? [Any] {
            // Mezcla de tipos: intenta convertir cada elemento a Int
            return anyArray.compactMap { elem in
                if let i = elem as? Int { return i }
                if let n = elem as? NSNumber { return n.intValue }
                if let s = elem as? String { return Int(s) }
                return nil
            }
        }

        // Si no hay campo o no es convertible, devolvemos vacío
        return []
    }
    
    func isUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
}

// MARK: - 4. ViewModel (Lógica de la vista)

@MainActor
final class SteamPatchNotesViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SteamApp] = []
    @Published var news: [NewsItem] = []
    @Published var isLoadingResults = false
    @Published var isLoadingNews = false
    @Published var isLoadingFavorites = false
    @Published var errorMessage: String?
    
    @Published var favoriteApps: [SteamApp] = [] // Objetos cargados
    @Published var selectedApp: SteamApp? // El juego actualmente seleccionado para noticias
    
    private let api = SteamAPI.shared
    private let rawg = RAWGAPI.shared
    private let firestoreService = FirestoreService.shared
    
    func search() {
        Task { await performSearch() }
    }
    
    func loadNews(for app: SteamApp) {
        selectedApp = app
        Task { await performLoadNews(appid: app.appid) }
    }
    
    func loadFavoriteApps() {
        Task { await performLoadFavorites() }
    }
    
    private func performLoadFavorites() async {
        guard firestoreService.isUserLoggedIn() else {
            errorMessage = "Debes iniciar sesión para ver tus juegos favoritos."
            favoriteApps = []
            return
        }
        
        isLoadingFavorites = true
        errorMessage = nil
        do {
            // 1. Obtener los IDs de Firebase
            let favoriteIDs = try await firestoreService.fetchFavoriteAppIDs()
            
            // 2. Obtener los objetos SteamApp de la API (para appid y nombre base)
            var steamApps = try await api.fetchApps(by: favoriteIDs)
            
            // 3. Para cada favorito, intentar resolver nombre desde RAWG y sobrescribir
            for i in steamApps.indices {
                let app = steamApps[i]
                do {
                    if let rawgName = try await rawg.resolveNameForSteamApp(appid: app.appid, fallbackName: app.name), !rawgName.isEmpty {
                        steamApps[i].name = rawgName
                    }
                } catch {
                    // En caso de error de RAWG, mantenemos el nombre de Steam
                    #if DEBUG
                    print("RAWG name resolve failed for appid \(app.appid): \(error.localizedDescription)")
                    #endif
                }
            }
            
            favoriteApps = steamApps
            
        } catch let error as NSError where error.code == 401 {
            errorMessage = "Error de sesión: Inicia sesión para cargar favoritos."
            favoriteApps = []
        } catch {
            // Captura el error de permisos de Firestore u otros errores
            print("Error detallado de favoritos: \(error.localizedDescription)")
            // 💡 Esta es la línea que reproduce tu error en pantalla
            errorMessage = "Error cargando juegos favoritos: \(error.localizedDescription)"
            favoriteApps = []
        }
        isLoadingFavorites = false
    }

    private func performSearch() async {
        isLoadingResults = true
        errorMessage = nil
        do {
            results = try await api.searchApps(query: query, limit: 100)
        } catch {
            errorMessage = "Error buscando juegos: \(error.localizedDescription)"
            results = []
        }
        isLoadingResults = false
    }

    private func performLoadNews(appid: Int) async {
        isLoadingNews = true
        errorMessage = nil
        news = []
        do {
            news = try await api.fetchNewsForApp(appid: appid, count: 25)
        } catch {
            errorMessage = "Error cargando noticias: \(error.localizedDescription)"
        }
        isLoadingNews = false
    }
}

// MARK: - 5. Vista (UI)

struct SteamPatchNotesView: View {
    @StateObject private var vm = SteamPatchNotesViewModel()
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            ZStack {
                // Asume que 'backgroundApp' y 'backgroundAccent' están en tus Assets
                LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), Color("backgroundAccent")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    header

                    HStack {
                        searchBar
                        favoriteAppMenu
                    }
                    .padding(.horizontal)

                    if vm.isLoadingResults {
                        ProgressView("Buscando…")
                            .tint(Color("ButtonColor"))
                    }

                    content
                }
                .padding(.top, 8)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await vm.search()
                vm.loadFavoriteApps() // Carga inicial de favoritos
            }
        }
    }
    
    // --- Header ---
    var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Steam Patchnotes")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color("things"))
                Text("Sigue las notas de parche y noticias de tus juegos favoritos")
                    .font(.subheadline)
                    .foregroundColor(Color("things").opacity(0.8))
            }
            Spacer()
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 28))
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    // --- Search Bar ---
    var searchBar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("ButtonColor"))
                TextField("Buscar juego en Steam...", text: $vm.query)
                    .foregroundColor(Color("things"))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onSubmit { vm.search() }
                if !vm.query.isEmpty {
                    Button(action: { vm.query = ""; Task { await vm.search() } }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(10)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: { vm.search() }) {
                Text("Buscar")
                    .font(.headline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("ButtonColor")))
                    .foregroundColor(.white)
            }
            .shadow(radius: 2)
        }
    }
    
    // 🔑 Menú de Favoritos (usa vm.favoriteApps)
    var favoriteAppMenu: some View {
        Menu {
            if vm.isLoadingFavorites {
                ProgressView("Cargando...")
            } else if vm.favoriteApps.isEmpty {
                Text("No hay favoritos")
            } else {
                ForEach(vm.favoriteApps) { app in
                    
                    // --- INICIO DE LA CORRECCIÓN ---
                    
                    Button(action: {
                        // Usar el nombre del favorito para buscarlo directamente
                        vm.query = app.name
                        vm.search()

                        // Opcional: limpiar selección de noticias para que el usuario elija desde resultados
                        withAnimation(.easeInOut) {
                            vm.selectedApp = nil
                            vm.news = []
                        }
                    }) {
                        Label(app.name, systemImage: "magnifyingglass")
                    }

                    // Acción secundaria: abrir noticias directamente si se desea
                    Button(action: {
                        vm.query = "" // no necesitamos búsqueda si vamos directo a noticias
                        withAnimation(.spring()) {
                            vm.selectedApp = app
                        }
                        vm.loadNews(for: app)
                    }) {
                        Label("Abrir noticias de \(app.name)", systemImage: "newspaper")
                    }
                    
                    // --- FIN DE LA CORRECCIÓN ---
                }
            }
        } label: {
            Image(systemName: vm.favoriteApps.isEmpty ? "star.slash" : "star.fill")
                .font(.title3)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("ButtonColor")))
                .foregroundColor(.white)
        }
        .shadow(radius: 2)
    }

    // --- Content ---
    var content: some View {
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: [.sectionHeaders]) {
                Section(header: listHeader) {
                    if let err = vm.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .padding()
                    }

                    ForEach(vm.results) { app in
                        appRow(app)
                            .padding(.horizontal)
                            .contextMenu { contextMenu(for: app) }
                    }
                }

                if let sel = vm.selectedApp { // Usamos vm.selectedApp
                    Section(header: newsHeader(for: sel)) {
                        if vm.isLoadingNews {
                            ProgressView("Cargando noticias…")
                                .tint(Color("ButtonColor"))
                                .padding()
                        } else if vm.news.isEmpty {
                            Text("No se encontraron noticias o patchnotes para este juego.")
                                .foregroundColor(Color("things").opacity(0.7))
                                .padding()
                        } else {
                            ForEach(vm.news) { item in
                                newsRow(item)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 30)
            .refreshable {
                vm.search()
                vm.loadFavoriteApps()
                if let sel = vm.selectedApp { vm.loadNews(for: sel) }
            }
        }
    }

    var listHeader: some View {
        HStack {
            Text("Resultados")
                .font(.title3.bold())
                .foregroundColor(Color("things"))
            Spacer()
            Text("Mostrando \(vm.results.count)")
                .font(.caption)
                .foregroundColor(Color("things").opacity(0.6))
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    func appRow(_ app: SteamApp) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                vm.selectedApp = app // Asignamos a vm.selectedApp
            }
            vm.loadNews(for: app)
        }) {
            HStack(spacing: 12) {
                // ... (AsyncImage y detalles)
                AsyncImage(url: URL(string: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(app.appid)/capsule_184x69.jpg")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .frame(width: 84, height: 38)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary)
                            .overlay(Image(systemName: "questionmark") )
                            .frame(width: 84, height: 38)
                    @unknown default:
                        EmptyView()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(Color("things"))
                        .lineLimit(2)
                    Text("appID: \(app.appid)")
                        .font(.caption)
                        .foregroundColor(Color("things").opacity(0.6))
                }

                Spacer()

                if vm.selectedApp?.appid == app.appid && vm.isLoadingNews {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("things").opacity(0.6))
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func contextMenu(for app: SteamApp) -> some View {
        Group {
            Button(action: {
                if let url = URL(string: "https://store.steampowered.com/app/\(app.appid)") { openURL(url) }
            }) { Label("Abrir en Steam", systemImage: "safari") }

            Button(action: {
                // Compatible con iOS/macOS
                #if os(iOS)
                UIPasteboard.general.string = "https://store.steampowered.com/app/\(app.appid)"
                #elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("https://store.steampowered.com/app/\(app.appid)", forType: .string)
                #endif
            }) { Label("Copiar enlace", systemImage: "doc.on.doc") }
        }
    }
    
    // ... (newsHeader, newsRow y stripHTML)
    func newsHeader(for app: SteamApp) -> some View {
        HStack {
            Text("Noticias / Patchnotes — \(app.name)")
                .font(.title3.bold())
                .foregroundColor(Color("things"))
            Spacer()
            Button(action: {
                if let url = URL(string: "https://store.steampowered.com/app/\(app.appid)") { openURL(url) }
            }) {
                Label("Tienda", systemImage: "cart")
                    .labelStyle(.iconOnly)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    func newsRow(_ item: NewsItem) -> some View {
        Button(action: {
            if let url = URL(string: item.url) { openURL(url) }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(Color("things"))
                        .lineLimit(2)
                    Spacer()
                    Text(item.dateFormatted)
                        .font(.caption2)
                        .foregroundColor(Color("things").opacity(0.6))
                }

                Text(stripHTML(item.contents))
                    .font(.body)
                    .foregroundColor(Color("things"))
                    .lineLimit(6)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let attributed = try? NSAttributedString(data: data,
                                                  options: [.documentType: NSAttributedString.DocumentType.html],
                                                  documentAttributes: nil) {
            return attributed.string
        }
        return html
    }
}

#Preview {
    SteamPatchNotesView()
}
