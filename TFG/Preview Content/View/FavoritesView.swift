import SwiftUI

struct FavoritesView: View {
    var favorites: [Game]
    
    var body: some View {
        VStack {
            
            Text("Tus Favoritos")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding(.top, 50) // Padding para no sobreponerse al notch
                .padding(.bottom, 20)
            
            if favorites.isEmpty {
                // Mensaje cuando no hay favoritos
                VStack {
                    Text("No tienes juegos favoritos.")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(Color("backgroundComponent"))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                .frame(maxHeight: .infinity) // Asegura que ocupe toda la pantalla
            } else {
                // Mostrar los juegos favoritos
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(favorites) { game in
                            GameCard2(game: game, favorites: .constant(favorites))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer() // Esto mantiene todo centrado en la vista
        }
        .background(Color("backgroundApp")) // Fondo que ocupa toda la pantalla
        .edgesIgnoringSafeArea(.all) // Ignorar áreas seguras para llenar toda la pantalla
    }
}

struct GameCard2: View {
    var game: Game
    @Binding var favorites: [Game]
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: game.backgroundImage)) { image in
                image.resizable()
                     .scaledToFill()
                     .frame(width: 100, height: 100)
                     .clipped()
                     .cornerRadius(10)
            } placeholder: {
                ProgressView()
            }
            
            Text(game.name)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color("backgroundComponent"))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    FavoritesView(favorites: [
        Game(id: 1, name: "Juego 1", backgroundImage: "https://via.placeholder.com/150"),
        Game(id: 2, name: "Juego 2", backgroundImage: "https://via.placeholder.com/150"),
        Game(id: 3, name: "Juego 3", backgroundImage: "https://via.placeholder.com/150")
    ])
}

