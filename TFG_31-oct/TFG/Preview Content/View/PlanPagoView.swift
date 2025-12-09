import SwiftUI
import PassKit

// MARK: - Modelo de Plan
struct Plan: Identifiable {
    let id = UUID()
    let nombre: String
    let descripcion: String
    let precio: String
    let precioDecimal: NSDecimalNumber
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

    let paymentHandler = PaymentHandler()

    let planes: [Plan] = [
        Plan(nombre: "Prueba gratuita", descripcion: "Acceso limitado a funciones", precio: "$0.00/mes", precioDecimal: 0.00),
        Plan(nombre: "Donaciones", descripcion: "Acceso limitado a funciones de forma temporal", precio: "$2.50", precioDecimal: 2.50),
        Plan(nombre: "Premium", descripcion: "Acceso ilimitado a todas las funciones.", precio: "$9.99/mes", precioDecimal: 9.99)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundApp")
                    .edgesIgnoringSafeArea(.all)

                List(planes) { plan in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(plan.nombre)
                            .font(.title2)
                            .bold()
                            .foregroundColor(Color("things"))

                        Text(plan.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(plan.precio)
                                .font(.headline)
                                .foregroundColor(Color("things"))

                            Spacer()

                            if PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]) {
                                ApplePayButton {
                                    pagar(plan: plan)
                                }
                                .frame(width: 150, height: 44)
                            } else {
                                Text("Apple Pay no disponible")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical)
                    .listRowBackground(Color.clear)
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .navigationTitle("Planes de Pago")
                .alert(isPresented: $showPaymentError) {
                    Alert(title: Text("Pago fallido"), message: Text("No se pudo completar el pago."), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showPaymentSuccess) {
                    Alert(title: Text("Pago exitoso"), message: Text("¡Gracias por tu compra!"), dismissButton: .default(Text("OK")))
                }
            }
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

