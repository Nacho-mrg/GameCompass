import SwiftUI

struct NoticiasView: View {
    @StateObject private var viewModel = NoticiasViewModel()
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false

    var filteredGiveaways: [Giveaway] {
        if searchText.isEmpty {
            return viewModel.giveaways
        } else {
            return viewModel.giveaways.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo degradado elegante
                LinearGradient(
                    gradient: Gradient(colors: [Color("backgroundApp"), Color("backgroundGradient")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)

                VStack {
                    // Campo búsqueda personalizado
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar giveaways...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color("backgroundComponent"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

                    if viewModel.giveaways.isEmpty && !isLoading {
                        Spacer()
                        Text("No se encontraron giveaways.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredGiveaways) { giveaway in
                                    GiveawayCard(giveaway: giveaway)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }

                    Spacer()
                }
                .padding(.top)
                .navigationTitle("Noticias - Giveaways")
                .navigationBarTitleDisplayMode(.inline)

                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    ProgressView("Cargando giveaways...")
                        .padding()
                        .background(Color("backgroundComponent"))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .task {
                isLoading = true
                await viewModel.fetchGiveaways()
                isLoading = false
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct GiveawayCard: View {
    let giveaway: Giveaway

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: giveaway.image)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                    .frame(height: 180)
                    .cornerRadius(15)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(15)
                        .shadow(radius: 6)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .foregroundColor(.gray)
                        .cornerRadius(15)
                @unknown default:
                    EmptyView()
                }
            }

            Text(giveaway.title)
                .font(.headline)
                .foregroundColor(.white)

            Text(giveaway.description)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(3)

            Link(destination: URL(string: giveaway.open_giveaway_url)!) {
                Text("Ver Giveaway")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("ButtonColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color("ButtonColor").opacity(0.6), radius: 6, x: 0, y: 3)
            }
        }
        .padding()
        .background(Color("backgroundComponent").opacity(0.85))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        .animation(.easeInOut, value: giveaway.id)
    }
}

#Preview {
    NoticiasView()
}

