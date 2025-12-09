//
//  TCGApp.swift
//  TFG
//
//  Created by Ignacio on 21/5/25.
//


import SwiftUI
import FirebaseCore

/**@main
struct appStorage: App {
    // Importante: inicializa Firebase si lo usas
    init() {
        FirebaseApp.configure()
    }

    @AppStorage("usuarioPagado") var usuarioPagado: Bool = false

    var body: some Scene {
        WindowGroup {
            if usuarioPagado {
                ContentView() // vista principal cuando ya pagó
            } else {
                LoginView()   // o una vista general antes de pagar
            }
        }
    }
}
*/
