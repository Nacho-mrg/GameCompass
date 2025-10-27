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
            let apps = try await api.searchApps(query: query, limit: 50)
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

// MARK: - View

struct SteamPatchNotesView: View {
    @StateObject private var vm = SteamPatchNotesViewModel()
    @State private var selectedApp: SteamApp?
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundApp").ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steam Patchnotes")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color("things"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack {
                            TextField("Buscar juego en Steam...", text: $vm.query)
                                .foregroundColor(Color("ButtonColor"))
                                .textFieldStyle(.roundedBorder)
                                .tint(Color("ButtonColor"))
                                .submitLabel(.search)
                                .onSubmit { vm.search() }

                            Button(action: { vm.search() }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color("things"))
                                    .padding(8)
                                    .background(Color("ButtonColor"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .shadow(radius: 4)
                        }
                        .padding(.horizontal)
                    }

                    if vm.isLoadingResults {
                        ProgressView("Buscando...")
                            .tint(Color("ButtonColor"))
                    }

                    ScrollView {
                        VStack(spacing: 16) {
                            if let err = vm.errorMessage {
                                Text(err)
                                    .foregroundColor(.red)
                                    .padding()
                            }

                            ForEach(vm.results) { app in
                                Button(action: {
                                    withAnimation(.easeInOut) { selectedApp = app }
                                    vm.loadNews(for: app)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(app.name)
                                                .font(.headline)
                                                .foregroundColor(Color("things"))
                                            Text("appID: \(app.appid)")
                                                .font(.caption)
                                                .foregroundColor(Color("things").opacity(0.6))
                                        }
                                        Spacer()
                                        if selectedApp?.appid == app.appid && vm.isLoadingNews {
                                            ProgressView().tint(Color("ButtonColor"))
                                        }
                                    }
                                    .padding()
                                    .background(Color("ButtonColor").opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(radius: 2)
                                }
                            }

                            if let sel = selectedApp {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Noticias / Patchnotes — \(sel.name)")
                                        .font(.title3.bold())
                                        .foregroundColor(Color("things"))

                                    if vm.isLoadingNews {
                                        ProgressView("Cargando noticias...")
                                            .tint(Color("ButtonColor"))
                                    } else if vm.news.isEmpty {
                                        Text("No se encontraron noticias o patchnotes para este juego.")
                                            .foregroundColor(Color("things").opacity(0.6))
                                    } else {
                                        ForEach(vm.news) { item in
                                            Button(action: {
                                                if let url = URL(string: item.url) {
                                                    openURL(url)
                                                }
                                            }) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text(item.title)
                                                        .font(.headline)
                                                        .foregroundColor(Color("things"))
                                                    Text(item.dateFormatted)
                                                        .font(.caption)
                                                        .foregroundColor(Color("things").opacity(0.7))
                                                    Text(stripHTML(item.contents))
                                                        .font(.body)
                                                        .foregroundColor(Color("things"))
                                                        .lineLimit(6)
                                                }
                                                .padding()
                                                .background(Color("ButtonColor").opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .shadow(radius: 2)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task { await vm.search() } // Cargar los primeros resultados alfabéticamente al iniciar
            }
        }
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

