import SwiftUI

struct NoticiasView: View {
    @StateObject private var viewModel = NoticiasViewModel()
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var animateHeader: Bool = true

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

                VStack(spacing: 16) {
                    // Encabezado centrado con shimmer sutil
                    ZStack {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Noticias & Giveaways")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("backgroundComponent").opacity(0.6))
                        .clipShape(Capsule())
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                    // Campo búsqueda personalizado
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar giveaways...", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color("backgroundComponent").opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)

                    if viewModel.giveaways.isEmpty && !isLoading {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("No se encontraron giveaways.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16, pinnedViews: []) {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                                ForEach(filteredGiveaways) { giveaway in
                                    GiveawayCard(giveaway: giveaway)
                                        .frame(maxWidth: 720, alignment: .center)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 8)
                .navigationTitle("Noticias")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Noticias · Giveaways")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }

                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Cargando giveaways...")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(Color("backgroundComponent").opacity(0.9))
                    .cornerRadius(14)
                    .shadow(radius: 10)
                }
            }
            .task {
                isLoading = true
                await viewModel.fetchGiveaways()
                isLoading = false
                animateHeader.toggle()
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
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        .animation(.easeInOut, value: giveaway.id)
    }
}

#Preview {
    NoticiasView()
}
