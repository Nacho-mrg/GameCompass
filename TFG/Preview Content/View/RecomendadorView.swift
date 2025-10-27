import SwiftUI

struct RecomendadorView: View {
    @AppStorage("usuarioPagado") var usuarioPagado: Bool = false
    @State private var horas: Double = 1.0
    @State private var duracion: String = "Corto"
    @State private var tematica: String = ""
    @State private var recomendacion: String = ""
    @State private var isLoading: Bool = false

    // api key expuesta en vez de ponerla en el .plist porque xcode mete ruido
    
    private let apiKey = "AIzaSyCUJfoLEyr7ogaTOOqxHnRpkI517tmmltM"

    let duraciones = ["Corto", "Largo"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("backgroundApp"), Color("ButtonColor")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Recomendador de Juegos")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.top, 50)

                if usuarioPagado {
                    VStack(spacing: 25) {
                        Stepper(value: $horas, in: 1...24, step: 1) {
                            Text("Horas al día: \(Int(horas))")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(BlurView(style: .systemMaterialDark))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)

                        Picker("Duración", selection: $duracion) {
                            ForEach(duraciones, id: \.self) { dur in
                                Text(dur)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(8)
                        .background(BlurView(style: .systemMaterialDark))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 5)

                        FloatingPlaceholderTextField(placeholder: "Introduce temática", text: $tematica)
                            .padding()
                            .background(BlurView(style: .systemMaterialDark))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 7)

                        Button(action: {
                            hideKeyboard()
                            if tematica.trimmingCharacters(in: .whitespaces).isEmpty {
                                recomendacion = "Por favor, introduce una temática."
                            } else {
                                generarRecomendacion()
                            }
                        }) {
                            Text(isLoading ? "Buscando..." : "Recomendar")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color("ButtonColor"), Color("ButtonColor").opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color("ButtonColor").opacity(0.7), radius: 15, x: 0, y: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .disabled(isLoading)
                        .scaleEffect(isLoading ? 0.95 : 1)
                        .animation(.easeOut(duration: 0.3), value: isLoading)
                    }
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 12)
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.white.opacity(0.75))

                        Text("Función disponible solo para usuarios con plan activo.")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Ve a la sección de planes para desbloquear.")
                            .font(.body.weight(.light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(BlurView(style: .systemMaterialDark))
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)
                }

                if !recomendacion.isEmpty {
                    ScrollView {
                        Text(recomendacion)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(BlurView(style: .systemUltraThinMaterial))
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    .frame(maxHeight: 280)
                    .padding(.bottom, 30)
                }

                Spacer()
            }
        }
    }

    func generarRecomendacion() {
        let prompt = """
        Recomiéndame un videojuego que se relacione con la temática "\(tematica)", dure "\(duracion)", y que pueda jugar aproximadamente \(Int(horas)) horas al día. Sé creativo, detallado y no repitas juegos famosos. Solo recomienda uno.
        """

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateText?key=\(apiKey)")!

        let requestBody: [String: Any] = [
            "prompt": [
                [
                    "text": prompt
                ]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            recomendacion = "Error al preparar la solicitud."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        isLoading = true
        recomendacion = ""

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.recomendacion = "Error de red: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.recomendacion = "Error: No se recibió respuesta de la API."
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                if let text = decoded.candidates.first?.content.parts.first?.text {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.recomendacion = text
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.recomendacion = "La API respondió, pero no se encontró texto."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.recomendacion = "No se pudo procesar la respuesta: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - BlurView UIKit Wrapper para fondos difuminados
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - TextField con placeholder flotante
struct FloatingPlaceholderTextField: View {
    var placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .foregroundColor(.white.opacity(isFocused || !text.isEmpty ? 0.6 : 0.35))
                .scaleEffect(isFocused || !text.isEmpty ? 0.8 : 1, anchor: .leading)
                .offset(y: isFocused || !text.isEmpty ? -30 : 0)
                .animation(.easeOut(duration: 0.3), value: isFocused || !text.isEmpty)

            TextField("", text: $text)
                .focused($isFocused)
                .foregroundColor(.white)
                .font(.title3.weight(.medium))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.top, 15)
        .padding(.horizontal, 12)
        .frame(height: 55)
    }
}

// MARK: - Extensión para esconder teclado
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

// MARK: - Modelos para la decodificación
struct GeminiResponse: Decodable {
    let candidates: [Candidate]
}

struct Candidate: Decodable {
    let content: Content
}

struct Content: Decodable {
    let parts: [Part]
}

struct Part: Decodable {
    let text: String
}

#Preview {
    RecomendadorView()
}

