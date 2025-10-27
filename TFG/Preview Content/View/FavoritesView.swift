import SwiftUI

struct FavoritesView: View {
    var favorites: [Game]
    
    var body: some View {
        VStack {
            Text("Tus Favoritos")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding(.top, 50)
                .padding(.bottom, 20)
            
            if favorites.isEmpty {
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
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(favorites) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                GameCard2(game: game)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .background(Color("backgroundApp"))
        .edgesIgnoringSafeArea(.all)
    }
}

struct GameCard2: View {
    var game: Game
    
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
    NavigationView {
        FavoritesView(favorites: [
            Game(id: 1, name: "Juego 1", backgroundImage: "https://via.placeholder.com/150"),
            Game(id: 2, name: "Juego 2", backgroundImage: "https://via.placeholder.com/150"),
            Game(id: 3, name: "Juego 3", backgroundImage: "https://via.placeholder.com/150")
        ])
    }
}

