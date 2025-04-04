import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MenuView()
                .tabItem {
                    Label("Menú", systemImage: "list.dash")
                }
            
            PlanPagoView()
                .tabItem {
                    Label("Plan de Pago", systemImage: "creditcard")
                }
        }
    }
}

struct MenuView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var searchText: String = ""
    @State private var showingLogin = false
    
    var filteredGames: [Game] {
        if searchText.isEmpty {
            return viewModel.games
        } else {
            return viewModel.games.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundApp")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .frame(width: 50, height: 50)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showingLogin = true
                        }) {
                            Image(systemName: "person.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("ButtonColor"))
                                .cornerRadius(10)
                        }
                        .fullScreenCover(isPresented: $showingLogin) {
                            LoginView()
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Menú")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    TextField("Buscar juegos", text: $searchText)
                        .padding()
                        .background(Color("backgroundComponent"))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(filteredGames) { game in
                                NavigationLink(destination: GameDetailView(game: game)) {
                                    GameCard(game: game)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchGames()
            }
            .navigationBarHidden(true)
        }
    }
}

struct GameCard: View {
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


struct Game: Codable, Identifiable {
    let id: Int
    let name: String
    let backgroundImage: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case backgroundImage = "background_image"
    }
}

#Preview {
    ContentView()
}

