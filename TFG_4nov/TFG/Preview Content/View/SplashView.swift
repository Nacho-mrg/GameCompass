import SwiftUI
import AVFoundation
import FirebaseAuth

struct SplashView: View {
    @State private var isActive = false
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = -180
    @State private var glowOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 40
    @State private var bgCircleScale: CGFloat = 0.8
    @State private var blurRadius: CGFloat = 40

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isUserLoggedIn = false

    var body: some View {
        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea()
                .blur(radius: blurRadius)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2)) {
                        blurRadius = 0
                    }

                    // Verificar si hay usuario logueado en Firebase
                    if Auth.auth().currentUser != nil {
                        isUserLoggedIn = true
                    }
                }

            if isActive {
                if isUserLoggedIn {
                    ContentView()
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            } else {
                VStack {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                            .frame(width: 220, height: 220)
                            .scaleEffect(bgCircleScale)
                            .opacity(glowOpacity)
                            .blur(radius: 20)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    glowOpacity = 1.0
                                    bgCircleScale = 1.1
                                }
                            }

                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                            .shadow(color: .white.opacity(0.15), radius: 20, x: 0, y: 10)
                            .opacity(logoOpacity)
                            .scaleEffect(logoScale)
                            .rotation3DEffect(.degrees(logoRotation), axis: (x: 0, y: 1, z: 0))
                            .onAppear {
                                withAnimation(.spring(response: 1.6, dampingFraction: 0.6)) {
                                    logoOpacity = 1.0
                                    logoScale = 1.0
                                    logoRotation = 0
                                }
                               
                            }
                    }

                    Text("Cargando tu experiencia...")
                        .font(.headline)
                        .foregroundColor(Color("things"))
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .padding(.top, 30)
                        .onAppear {
                            withAnimation(.easeOut(duration: 2).delay(0.8)) {
                                textOpacity = 1.0
                                textOffset = 0
                            }
                        }

                    Spacer()
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }

}

