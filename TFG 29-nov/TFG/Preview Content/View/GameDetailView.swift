import SwiftUI

struct GameDetailView: View {
    @StateObject private var viewModel = GameDetailViewModel()
    var game: Game
    @State private var scrollOffset: CGFloat = 0
    @State private var titleOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Fondo con gradiente animado
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("backgroundApp"),
                    Color("backgroundAccent"),
                    Color.purple.opacity(0.3),
                    Color("backgroundApp")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Efecto de partículas sutiles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .global).minY) { value in
                                scrollOffset = value
                                // CORRECCIÓN: Usar 100.0 en lugar de 100
                                titleOpacity = max(0, 1 - (abs(value) / 100.0))
                            }
                    }
                    .frame(height: 0)
                    
                    if let gameDetail = viewModel.gameDetail {
                        // Header con imagen parallax
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: gameDetail.backgroundImage)) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: UIScreen.main.bounds.width,
                                        height: max(400 - scrollOffset, 280)
                                    )
                                    .offset(y: scrollOffset > 0 ? -scrollOffset * 0.8 : 0)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .clear,
                                                .black.opacity(0.9)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } placeholder: {
                                ZStack {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.purple.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                }
                            }
                            
                            // Título que se desvanece al hacer scroll
                            VStack(alignment: .leading, spacing: 8) {
                                Text(gameDetail.name)
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
                                    .opacity(titleOpacity)
                                
                                // Línea decorativa bajo el título
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.yellow, .orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 3)
                                    .frame(width: 100 * titleOpacity)
                                    .opacity(titleOpacity)
                            }
                            .padding(.horizontal, 25)
                            .padding(.bottom, 30)
                        }
                        .frame(height: 400)
                        
                        // Tarjeta de descripción con estilo creativo
                        VStack(alignment: .leading, spacing: 25) {
                            // Header de la sección con icono
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text("DESCRIPCIÓN")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(Color("things"))
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 5)
                            
                            // Contenido de la descripción
                            Text(gameDetail.descriptionRaw)
                                .foregroundColor(Color("things"))
                                .lineSpacing(8)
                                .padding(25)
                                .background(
                                    ZStack {
                                        // Fondo con bordes redondeados
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color("backgroundComponent"))
                                        
                                        // Efecto de borde luminoso
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        .white.opacity(0.3),
                                                        .clear,
                                                        .white.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                                )
                        }
                        .padding(20)
                        .padding(.top, 20)
                        
                    } else {
                        // Loader creativo
                        VStack(spacing: 25) {
                            Spacer()
                            
                            ZStack {
                                // Círculo animado
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 6
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Text("CARGANDO AVENTURA...")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(Color("things"))
                                .tracking(1.5)
                            
                            Spacer()
                        }
                        .frame(height: 400)
                        .onAppear {
                            viewModel.fetchGameDetail(gameID: game.id)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        GameDetailView(game: Game(
            id: 1,
            name: "The Legend of Zelda: Breath of the Wild",
            backgroundImage: "https://images.igdb.com/igdb/image/upload/t_720p/co1x7z.jpg"
        ))
    }
    .preferredColorScheme(.dark)
}
