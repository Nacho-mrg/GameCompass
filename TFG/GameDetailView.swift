import SwiftUI

struct GameDetailView: View {
    @StateObject private var viewModel = GameDetailViewModel()
    var game: Game
    
    var body: some View {
        ZStack {
            Color("backgroundApp") // Fondo con color personalizado desde Assets
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if let gameDetail = viewModel.gameDetail {
                    AsyncImage(url: URL(string: gameDetail.backgroundImage)) { image in
                        image.resizable()
                             .scaledToFit()
                             .frame(height: 300)
                             .cornerRadius(15)
                    } placeholder: {
                        ProgressView()
                    }
                    
                    Text(gameDetail.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color("things")) // Usar el color "things" de Assets
                        .padding()
                    
                    Text(gameDetail.descriptionRaw)
                        .foregroundColor(Color("things")) // Usar el color "things" para la descripción
                        .padding()
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel.fetchGameDetail(gameID: game.id)
                        }
                }
            }
            .padding()
        }
    }
}

#Preview {
    GameDetailView(game: Game(id: 1, name: "Ejemplo de Juego", backgroundImage: "https://example.com/image.jpg"))
}

