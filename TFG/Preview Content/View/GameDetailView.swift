import SwiftUI

struct GameDetailView: View {
    @StateObject private var viewModel = GameDetailViewModel()
    var game: Game
    
    var body: some View {
        ZStack {
            Color("backgroundApp")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView { // Agrego ScrollView para permitir desplazamiento
                VStack(spacing: 20) { // Agregar espaciado entre los elementos
                    if let gameDetail = viewModel.gameDetail {
                        
                        // Imagen del juego con un borde sutil
                        AsyncImage(url: URL(string: gameDetail.backgroundImage)) { image in
                            image.resizable()
                                 .scaledToFit()
                                 .frame(height: 300)
                                 .cornerRadius(15)
                                 .shadow(radius: 10)
                        } placeholder: {
                            ProgressView()
                        }
                        
                        // Título del juego
                        Text(gameDetail.name)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(Color("things"))
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Descripción del juego con más estilo y padding
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Descripción")
                                .font(.headline)
                                .foregroundColor(Color("things"))
                            
                            Text(gameDetail.descriptionRaw)
                                .foregroundColor(Color("things"))
                                .lineLimit(nil) // Permite el salto de línea
                                .padding()
                                .background(Color("backgroundComponent"))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        .padding([.horizontal, .bottom], 20)
                    } else {
                        // Loader mientras se obtiene la información
                        ProgressView()
                            .onAppear {
                                viewModel.fetchGameDetail(gameID: game.id)
                            }
                            .padding()
                    }
                }
                .padding(.horizontal) // Padding general en todo el VStack
            }
        }
    }
}

#Preview {
    GameDetailView(game: Game(id: 1, name: "Ejemplo de Juego", backgroundImage: "https://example.com/image.jpg"))
}

