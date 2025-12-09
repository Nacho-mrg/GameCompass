import SwiftUI
import PassKit

// MARK: - Modelo de Plan
struct Plan: Identifiable {
    let id = UUID()
    let nombre: String
    let descripcion: String
    let precio: String
    let precioDecimal: NSDecimalNumber
    let iconName: String
}

// MARK: - Botón nativo Apple Pay (PKPaymentButton) con acción
struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }

        @objc func tapped() {
            action()
        }
    }
}

// MARK: - Vista principal
struct PlanPagoView: View {
    @AppStorage("usuarioPagado") var usuarioPagado: Bool = false
    @State private var showPaymentError = false
    @State private var showPaymentSuccess = false
    @State private var searchText: String = ""

    let paymentHandler = PaymentHandler()

    let planes: [Plan] = [
        Plan(nombre: "Prueba gratuita", descripcion: "Acceso limitado a funciones", precio: "$0.00/mes", precioDecimal: 0.00, iconName: "sparkles"),
        Plan(nombre: "Donaciones", descripcion: "Acceso limitado a funciones de forma temporal", precio: "$2.50", precioDecimal: 2.50, iconName: "heart.fill"),
        Plan(nombre: "Premium", descripcion: "Acceso ilimitado a todas las funciones.", precio: "$9.99/mes", precioDecimal: 9.99, iconName: "crown.fill")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundApp")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Decorative Header
                    ZStack {
                        LinearGradient(colors: [Color.blue.opacity(0.35), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .overlay(
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.25))
                                        .blur(radius: 30)
                                        .frame(width: 160, height: 160)
                                        .offset(x: -120, y: -30)
                                    Circle()
                                        .fill(Color.purple.opacity(0.25))
                                        .blur(radius: 30)
                                        .frame(width: 140, height: 140)
                                        .offset(x: 120, y: 20)
                                }
                            )

                        VStack(spacing: 8) {
                            Text("Planes de Pago")
                                .font(.largeTitle).bold()
                                .foregroundStyle(Color("things"))
                            Text("Elige el plan que mejor se adapte a ti")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                    }

                    // Search (decorative)
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar plan...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Cards
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(planes) { plan in
                                PlanCard(plan: plan) { selected in
                                    pagar(plan: selected)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showPaymentError) {
                Alert(title: Text("Pago fallido"), message: Text("No se pudo completar el pago."), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showPaymentSuccess) {
                Alert(title: Text("Pago exitoso"), message: Text("¡Gracias por tu compra!"), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Card de Plan
    struct PlanCard: View {
        let plan: Plan
        var onPay: (Plan) -> Void

        var accentColor: Color {
            switch plan.nombre.lowercased() {
            case _ where plan.nombre.lowercased().contains("prueba"):
                return .teal
            case _ where plan.nombre.lowercased().contains("donacion") || plan.nombre.lowercased().contains("donaciones"):
                return .pink
            default:
                return .yellow
            }
        }

        var body: some View {
            ZStack {
                // Glassy background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 46, height: 46)
                            Image(systemName: plan.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.nombre)
                                .font(.title3).bold()
                                .foregroundStyle(Color("things"))
                            Text(plan.descripcion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(plan.precio)
                            .font(.headline)
                            .foregroundStyle(Color("things"))
                    }

                    Divider().opacity(0.2)

                    HStack {
                        Spacer()
                        if PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]) {
                            ApplePayButton {
                                onPay(plan)
                            }
                            .frame(width: 170, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                        } else {
                            Text("Apple Pay no disponible")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
        }
    }

    func pagar(plan: Plan) {
        paymentHandler.startPayment(plan: plan) { success in
            if success {
                usuarioPagado = true
                showPaymentSuccess = true
                print("Usuario ha pagado el plan: \(plan.nombre)")
            } else {
                showPaymentError = true
                print("Error al procesar el pago.")
            }
        }
    }
}

// MARK: - Handler de Pago con Apple Pay
class PaymentHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    var completionHandler: ((Bool) -> Void)?

    func startPayment(plan: Plan, completion: @escaping (Bool) -> Void) {
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]) else {
            print("Apple Pay no está disponible o no hay tarjetas configuradas.")
            completion(false)
            return
        }

        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.com.tuapp" // ← Reemplaza con tu merchant real
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "US" // Cambia si estás en otro país
        paymentRequest.currencyCode = "USD" // Cambia si usas otra moneda

        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: plan.nombre, amount: plan.precioDecimal),
            PKPaymentSummaryItem(label: "TuApp", amount: plan.precioDecimal) // Total
        ]

        let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        controller.delegate = self

        controller.present { success in
            if success {
                print("Apple Pay presentado correctamente")
            } else {
                print("Error al presentar Apple Pay")
                completion(false)
            }
        }

        self.completionHandler = completion
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // Se resuelve en didAuthorizePayment
        }
    }

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Aquí normalmente enviarías el token al backend para confirmar
        let success = true // Simulación de éxito

        if success {
            completion(.init(status: .success, errors: nil))
            completionHandler?(true)
        } else {
            completion(.init(status: .failure, errors: nil))
            completionHandler?(false)
        }
    }
}

// MARK: - Preview
#Preview {
    PlanPagoView()
}
