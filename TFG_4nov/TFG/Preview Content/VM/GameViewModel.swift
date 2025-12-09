import Foundation

class GameViewModel: ObservableObject {
    @Published var games: [Game] = []
    private var currentPage = 1
    private let pageSize = 40
    private var isLoading = false

    func fetchGames() {
        guard !isLoading else { return }
        isLoading = true

        guard let url = URL(string: "https://api.rawg.io/api/games?key=b9355a95d4084728bb4486202b0a231e&page=\(currentPage)&page_size=\(pageSize)") else {
            print("URL no válida")
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { self.isLoading = false }

            if let error = error {
                print("Error en la solicitud: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No se recibió data")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(GameResponse.self, from: data)
                DispatchQueue.main.async {
                    self.games.append(contentsOf: decodedResponse.results)
                    self.currentPage += 1
                }
            } catch {
                print("Error al decodificar JSON: \(error)")
            }
        }.resume()
    }
}

struct GameResponse: Codable {
    let results: [Game]
}

