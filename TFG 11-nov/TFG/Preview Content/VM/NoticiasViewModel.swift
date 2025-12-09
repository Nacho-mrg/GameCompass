//
//  NoticiasViewModel.swift
//  TFG
//
//  Created by Ignacio on 12/5/25.
//


import Foundation

@MainActor
class NoticiasViewModel: ObservableObject {
    @Published var giveaways: [Giveaway] = []

    func fetchGiveaways() async {
        guard let url = URL(string: "https://www.gamerpower.com/api/giveaways") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([Giveaway].self, from: data)
            self.giveaways = decoded
        } catch {
            print("Error al obtener los datos: \(error.localizedDescription)")
        }
    }
}
