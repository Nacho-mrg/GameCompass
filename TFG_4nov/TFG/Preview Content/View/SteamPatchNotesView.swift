import SwiftUI

// MARK: - Models

struct AppListResponse: Codable {
    let applist: Applist
    struct Applist: Codable {
        let apps: [SteamApp]
    }
}

struct SteamApp: Codable, Identifiable {
    let appid: Int
    let name: String
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
    let is_external_url: Bool
    let author: String?
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

// MARK: - Steam API

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
        cachedAppList = decoded.applist.apps
        return decoded.applist.apps
    }

    func searchApps(query: String = "", limit: Int = 50) async throws -> [SteamApp] {
        let all = try await fetchAppListIfNeeded()
        let filtered: [SteamApp]
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Si no hay búsqueda, devolver los primeros juegos ordenados alfabéticamente
            filtered = Array(all.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }).prefix(limit))
        } else {
            let lowered = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            filtered = all.filter { $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(lowered) }
            .prefix(limit)
            .map { $0 }
        }
        return filtered
    }

    func fetchNewsForApp(appid: Int, count: Int = 10, maxlength: Int = 10000) async throws -> [NewsItem] {
        var components = URLComponents(string: "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/")!
        components.queryItems = [
            URLQueryItem(name: "appid", value: String(appid)),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "maxlength", value: String(maxlength))
        ]
        let url = components.url!
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

// MARK: - ViewModel

@MainActor
final class SteamPatchNotesViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SteamApp] = []
    @Published var news: [NewsItem] = []
    @Published var isLoadingResults = false
    @Published var isLoadingNews = false
    @Published var errorMessage: String?

    private let api = SteamAPI.shared

    func search() {
        Task { await performSearch() }
    }

    private func performSearch() async {
        isLoadingResults = true
        errorMessage = nil
        do {
            let apps = try await api.searchApps(query: query, limit: 100)
            results = apps
        } catch {
            errorMessage = "Error buscando juegos: \(error.localizedDescription)"
            results = []
        }
        isLoadingResults = false
    }

    func loadNews(for app: SteamApp) {
        Task { await performLoadNews(appid: app.appid) }
    }

    private func performLoadNews(appid: Int) async {
        isLoadingNews = true
        errorMessage = nil
        news = []
        do {
            let items = try await api.fetchNewsForApp(appid: appid, count: 25)
            news = items
        } catch {
            errorMessage = "Error cargando noticias: \(error.localizedDescription)"
        }
        isLoadingNews = false
    }
}

// MARK: - View (Decorated)

struct SteamPatchNotesView: View {
    @StateObject private var vm = SteamPatchNotesViewModel()
    @State private var selectedApp: SteamApp?
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("backgroundApp"), Color("backgroundAccent")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    header

                    searchBar
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
            .task { await vm.search() }
        }
    }

    // MARK: - Header

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

    // MARK: - Search Bar

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

    // MARK: - Content

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

                if let sel = selectedApp {
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
                if let sel = selectedApp { vm.loadNews(for: sel) }
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
                selectedApp = app
            }
            vm.loadNews(for: app)
        }) {
            HStack(spacing: 12) {
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

                if selectedApp?.appid == app.appid && vm.isLoadingNews {
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
                UIPasteboard.general.string = "https://store.steampowered.com/app/\(app.appid)"
            }) { Label("Copiar enlace", systemImage: "doc.on.doc") }
        }
    }

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
        let data = Data(html.utf8)
        if let attributed = try? NSAttributedString(data: data,
                                                    options: [.documentType: NSAttributedString.DocumentType.html],
                                                    documentAttributes: nil) {
            return attributed.string
        }
        return html
    }
}

// MARK: - Preview

struct SteamPatchNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SteamPatchNotesView()
            .preferredColorScheme(.dark)
    }
}

