import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class FavoritesStore: ObservableObject {
    @Published var favorites: [Game] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async { [weak self] in
                self?.favorites = []
                self?.errorMessage = nil
            }
            return
        }
        isLoading = true
        errorMessage = nil
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error obteniendo favoritos: \(error.localizedDescription)"
                    return
                }
                let data = snapshot?.data() ?? [:]
                let ids = data["favoriteIDs"] as? [Int] ?? []
                // Crea placeholders con nombre vacío; la vista que tenga catálogo podrá reconciliar.
                self.favorites = ids.map { Game(id: $0, name: "", backgroundImage: "") }
            }
        }
    }

    func setFavorites(from games: [Game]) {
        // Permite actualizar con juegos completos cuando se dispone del catálogo
        let ids = Set(favorites.map { $0.id })
        let enriched = games.filter { ids.contains($0.id) }
        if !enriched.isEmpty {
            self.favorites = enriched
        }
    }
}
