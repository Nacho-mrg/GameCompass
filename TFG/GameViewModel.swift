//
//  GameViewModel.swift
//  TCG
//
//  Created by Ignacio on 3/4/25.
//


import Foundation

class GameViewModel: ObservableObject {
    @Published var games: [Game] = []

    func fetchGames() {
        guard let url = URL(string: "https://api.rawg.io/api/games?key=b9355a95d4084728bb4486202b0a231e") else {
            print("URL no válida")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    self.games = decodedResponse.results
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
