# GameCompass
- Una app de videojuegos

  ```swift
  //
//  AppDelegate.swift
//  TCG
//
//  Created by Ignacio on 3/4/25.
//


import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
          //empezar la app en la vista de splash
          SplashView()
      }
    }
  }
}

  ```
