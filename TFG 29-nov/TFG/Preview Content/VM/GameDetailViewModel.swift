//
//  GameDetailViewModel.swift
//  TFG
//
//  Created by Ignacio on 3/4/25.
//


import Foundation

class GameDetailViewModel: ObservableObject {
    @Published var gameDetail: GameDetail?
    
    func fetchGameDetail(gameID: Int) {
        guard let url = URL(string: "https://api.rawg.io/api/games/\(gameID)?key=b9355a95d4084728bb4486202b0a231e") else {
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
                let decodedResponse = try JSONDecoder().decode(GameDetail.self, from: data)
                DispatchQueue.main.async {
                    self.gameDetail = decodedResponse
                }
            } catch {
                print("Error al decodificar JSON: \(error)")
            }
        }.resume()
    }
}

struct GameDetail: Codable {
    let id: Int
    let name: String
    let backgroundImage: String
    let descriptionRaw: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case backgroundImage = "background_image"
        case descriptionRaw = "description_raw"
    }
}
