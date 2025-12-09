import SwiftUI
import AVFoundation
import FirebaseAuth
import UIKit

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
    // Animaciones avanzadas
    @State private var gradientPhase: CGFloat = 0
    @State private var pulse: CGFloat = 1.0
    @State private var shimmerPhase: CGFloat = 0
    @State private var showProgress = false
    @State private var progress: Double = 0.0

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isUserLoggedIn = false
    
    private let impactLight = UIImpactFeedbackGenerator(style: .medium)
    private let impactMedium = UIImpactFeedbackGenerator(style: .heavy)
    private let notifyGenerator = UINotificationFeedbackGenerator()
    
    private func triggerImpact(_ generator: UIImpactFeedbackGenerator) {
        generator.prepare()
        generator.impactOccurred()
    }
    private func triggerSuccess() {
        notifyGenerator.prepare()
        notifyGenerator.notificationOccurred(.success)
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente animado
            AngularGradient(gradient: Gradient(colors: [
                Color("backgroundApp"),
                Color("backgroundAccent").opacity(0.7),
                Color("backgroundApp").opacity(0.9),
                Color("backgroundAccent")
            ]), center: .center, angle: .degrees(Double(gradientPhase) * 360))
            .ignoresSafeArea()
            .overlay(
                // Partículas sutiles
                ZStack {
                    ForEach(0..<18, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: CGFloat(Int.random(in: 4...10)), height: CGFloat(Int.random(in: 4...10)))
                            .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                      y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                            .blur(radius: 2)
                            .opacity(0.7)
                            .offset(x: sin(CGFloat(i)) * 6, y: cos(CGFloat(i)) * 6)
                            .animation(.easeInOut(duration: 3).repeatForever().delay(Double(i) * 0.1), value: gradientPhase)
                    }
                }
            )
            .blur(radius: blurRadius)
            .onAppear {
                withAnimation(.easeInOut(duration: 2)) { blurRadius = 0 }
                withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { gradientPhase = 1 }
                triggerImpact(impactLight)

                // Verificar login
                if Auth.auth().currentUser != nil { isUserLoggedIn = true }
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
                VStack(spacing: 22) {
                    Spacer()

                    // Tarjeta "liquid glass" para el logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .strokeBorder(LinearGradient(colors: [
                                        .white.opacity(0.35), .white.opacity(0.05)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                    .blendMode(.plusLighter)
                            )
                            .frame(width: 220, height: 220)
                            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 20)
                            .scaleEffect(bgCircleScale * pulse)
                            .opacity(glowOpacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    glowOpacity = 1.0
                                    bgCircleScale = 1.05
                                }
                                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                                    pulse = 1.04
                                }
                                triggerImpact(impactLight)
                            }

                        // Logo con shimmer y giro inicial
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                            .overlay(
                                // Shimmer
                                LinearGradient(gradient: Gradient(colors: [
                                    .clear, .white.opacity(0.35), .clear
                                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                .rotationEffect(.degrees(25))
                                .offset(x: shimmerPhase)
                                .mask(
                                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                                        .frame(width: 160, height: 160)
                                )
                            )
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
                                triggerImpact(impactMedium)
                                withAnimation(.linear(duration: 1.8).delay(0.6)) {
                                    shimmerPhase = 220
                                }
                                triggerImpact(impactLight)
                            }
                    }

                    VStack(spacing: 12) {
                        Text("Cargando tu experiencia...")
                            .font(.headline)
                            .foregroundColor(Color("things"))
                            .opacity(textOpacity)
                            .offset(y: textOffset)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.6).delay(0.6)) {
                                    textOpacity = 1.0
                                    textOffset = 0
                                }
                            }

                        // Barra de progreso estilizada
                        if showProgress {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [Color("ButtonColor"), Color("ButtonColor").opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: CGFloat(progress) * 220, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                            .frame(width: 220)
                            .transition(.opacity)
                        }
                    }

                    Spacer()
                }
                .transition(.opacity)
                .onAppear {
                    // Simular progreso
                    showProgress = true
                    progress = 0
                    Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
                        progress += 0.03
                        if Int((progress * 100).rounded()) % 20 == 0 {
                            triggerImpact(impactLight)
                        }
                        if progress >= 1.0 {
                            triggerSuccess()
                            timer.invalidate()
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            self.isActive = true
                        }
                        triggerSuccess()
                    }
                }
            }
        }
    }

}

#Preview {
  SplashView()
}
