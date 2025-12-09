//
//  AuthManager.swift
//  TFG
//
//  Created by Ignacio on 12/5/25.
//


import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = Auth.auth().currentUser != nil

    static let shared = AuthManager()

    private init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}

