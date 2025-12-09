import SwiftUI
import UIKit // Necesario para la extensión hideKeyboard()

// MARK: - Estructuras de Decodificación para la API de Gemini (Fuera de la Vista)
// Hacemos todas las propiedades potencialmente faltantes OPCIONALES (var?) para mayor robustez

// Estructura de respuesta exitosa (formato de éxito)
struct GeminiResponse: Decodable {
    // Hacemos 'candidates' opcional por si la API lo omite
    let candidates: [CandidateBlock]?
    let promptFeedback: PromptFeedback?
}

struct CandidateBlock: Decodable {
    let content: ContentPart?
    let safetyRatings: [SafetyRating]?
}

struct ContentPart: Decodable {
    // Hacemos 'parts' opcional por si la API lo omite en la respuesta
    let parts: [Part]?
}

struct Part: Decodable {
    let text: String?
}

// Estructuras para manejar el feedback de seguridad
struct PromptFeedback: Decodable {
    let blockReason: String?
    let safetyRatings: [SafetyRating]?
}

struct SafetyRating: Decodable {
    let category: String
    let probability: String
}

// Estructura de respuesta de error (formato de fallo HTTP 400/403)
struct GeminiErrorResponse: Decodable {
    let error: ErrorDetails
}

struct ErrorDetails: Decodable {
    let code: Int
    let message: String
}


// MARK: - Vista Principal

struct RecomendadorView: View {
    @AppStorage("usuarioPagado") var usuarioPagado: Bool = true
    @State private var horas: Double = 1.0
    @State private var duracion: String = "Corto"
    @State private var tematica: String = ""
    @State private var recomendacion: String = ""
    @State private var isLoading: Bool = false

    // CLAVE DE API: ¡ACTUALIZADA CON TU VALOR!
    // -> Si esta clave no funciona, por favor, genera una nueva en Google AI Studio.
    private let geminiApiKey = "AIzaSyAv8zNigczoz1iKj0WwcPYSnv1CkLbjrS8"
    
    // Las siguientes ya NO se usan con el endpoint de Gemini:
    private let apiKey = ""
    private let projectID = "45085403130"
    private let location = "europe-west1"

    let duraciones = ["Corto","Medio","Largo"]

    var body: some View {
        ZStack {
            // Asegúrate de que los colores "backgroundApp" y "ButtonColor" existen en Assets
            LinearGradient(colors: [Color("backgroundApp"), Color("ButtonColor")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Recomendador de Juegos")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 50)

                if usuarioPagado {

                    VStack(spacing: 20) {

                        Stepper("Horas al día: \(Int(horas))", value: $horas, in: 1...24)
                            .padding()
                            .background(.ultraThickMaterial)
                            .cornerRadius(15)

                        Picker("Duración", selection: $duracion) {
                            ForEach(duraciones, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(.ultraThinMaterial)
                            .cornerRadius(15)

                        TextField("Introduce temática", text: $tematica)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                        
                        

                        Button(action: {
                            hideKeyboard()
                            generarRecomendacion()
                        }) {
                            Text(isLoading ? "Buscando..." : "Recomendar")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("ButtonColor"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .disabled(isLoading)

                    }.padding(.horizontal)

                } else {
                    Text("Función disponible solo para usuarios con plan activo.")
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(20)
                }

                if !recomendacion.isEmpty {
                    ScrollView {
                        Text(recomendacion)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 280)
                }

                Spacer()
            }
        }
    }

    // MARK: - Función Actualizada para la API de Gemini
    func generarRecomendacion() {
        guard !tematica.trimmingCharacters(in: .whitespaces).isEmpty else {
            recomendacion = "Por favor, introduce una temática."
            return
        }

        // 1. URL de la API de Gemini (generativelanguage.googleapis.com)
        // La clave se añade SOLO si no está vacía
        let keyQuery = geminiApiKey.isEmpty ? "" : "?key=\(geminiApiKey)"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent\(keyQuery)"
        
        guard let url = URL(string: urlString) else {
            recomendacion = "URL inválida."
            return
        }

        let promptText = "Recomiéndame un videojuego con temática \"\(tematica)\", duración \"\(duracion)\" y tiempo de juego diario de aproximadamente \(Int(horas)) horas. Sé creativo y explica por qué encaja. Pero no me des una respuesta de chat, hazmelo en un formato mas visible, tampoco te esplayes mucho con las respuesta se claro y conciso. Ademas ahorrate la parte de como experto en el campo, dime directamente el juego."

        // 2. Construcción robusta del JSON Body para la API de Gemini
        let body: [String: Any] = [
            // INSTRUCCIÓN DE SISTEMA ACTUALIZADA: Simplificada para enfocarse en la calidad
            "systemInstruction": [
                "parts": [
                    // El modelo debe dar una recomendación detallada. El formato Markdown se deja porque el modelo lo utiliza de forma natural y la respuesta real lo contenía.
                    ["text": "Actúa como un experto en videojuegos. Ofrece una recomendación detallada que cumpla con los requisitos de temática, duración y tiempo de juego diario."]
                ]
            ],
            // Contenido de la solicitud (el prompt del usuario)
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            // Uso de "generationConfig" (corregido)
            "generationConfig": [
                "temperature": 0.7,
                // LÍMITE DE TOKENS AUMENTADO: Se ajusta a 2000 para permitir respuestas largas (el ejemplo real usó ~1459)
                "maxOutputTokens": 2000
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            recomendacion = "Error creando la solicitud."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        isLoading = true
        recomendacion = ""

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                DispatchQueue.main.async {
                    self.recomendacion = "Error de red: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.recomendacion = "Error de red: Respuesta de la API vacía. (Data Missing)"
                }
                return
            }
            
            // ✅ DEBUG: Imprime la respuesta JSON recibida
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG API RESPONSE JSON: \(jsonString)")
            } else {
                print("DEBUG API RESPONSE: Received data, but couldn't decode as UTF-8 string.")
            }
            
            // --- INICIO: Manejo de la Respuesta del Servidor (HTTP) ---
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let status = httpResponse.statusCode
                // Intentar decodificar la respuesta como un error JSON de la API
                do {
                    let decoder = JSONDecoder()
                    let errorResponse = try decoder.decode(GeminiErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.recomendacion = "Error HTTP \(status) - \(errorResponse.error.message)"
                    }
                } catch {
                    // Si falla la decodificación del error, mostramos el mensaje HTTP genérico
                    DispatchQueue.main.async {
                        let serverMessage = String(data: data, encoding: .utf8) ?? "No hay mensaje del servidor."
                        if status == 400 {
                            // Se muestra este mensaje si el error no se pudo decodificar correctamente
                            self.recomendacion = "Error HTTP 400 - Solicitud inválida. (Ver Consola)"
                        } else if status == 403 || status == 401 {
                            self.recomendacion = "Error HTTP \(status) - Acceso Denegado. Clave no válida o sin permisos."
                        } else if status == 429 {
                            self.recomendacion = "Error HTTP 429 (Límite de solicitudes alcanzado). Intenta más tarde."
                        } else {
                            self.recomendacion = "Error HTTP \(status) inesperado. \(serverMessage)"
                        }
                        print("Error: Fallo al decodificar la respuesta de error de la API. Datos sin procesar: \(serverMessage)")
                    }
                }
                return
            }
            // --- FIN: Manejo de la Respuesta del Servidor (HTTP) ---
            
            // 3. Decodificación de la respuesta exitosa (HTTP 200)
            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(GeminiResponse.self, from: data)

                // Lógica para manejar contenido bloqueado en una respuesta 200 OK
                if let blockReason = apiResponse.promptFeedback?.blockReason {
                    DispatchQueue.main.async {
                        // MENSAJE MEJORADO: Ahora incluye la razón de bloqueo.
                        self.recomendacion = "Contenido bloqueado por filtros de seguridad. Razón: \(blockReason)."
                    }
                    return
                }

                // Buscar el texto dentro de la estructura anidada.
                if let candidate = apiResponse.candidates?.first,
                    let part = candidate.content?.parts?.first,
                    let text = part.text {
                    
                    DispatchQueue.main.async {
                        self.recomendacion = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } else {
                    DispatchQueue.main.async {
                        // Si la decodificación es exitosa pero no hay 'text' o candidatos (respuesta vacía)
                        self.recomendacion = "Respuesta de la API vacía. Por favor, revisa la consola para ver el JSON de respuesta."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    // 🛑 DEBUG: Muestra el error de decodificación completo
                    print("Decoding Error: \(error)")
                    
                    // --- DEBUG ADICIONAL ---
                    let rawDataString = String(data: data, encoding: .utf8) ?? "No se pudo convertir a cadena."
                    print("Raw API Data (on decoding failure): \(rawDataString)")
                    // --- FIN DEBUG ADICIONAL ---
                    
                    self.recomendacion = "Error de decodificación: Respuesta de éxito (200 OK) mal formada. Revise la consola."
                }
            }

        }.resume()
    }

}

// MARK: - Extensión para ocultar el teclado

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    RecomendadorView()
}

