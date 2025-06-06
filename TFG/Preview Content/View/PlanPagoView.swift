import SwiftUI

struct Plan: Identifiable {
    let id = UUID()
    let nombre: String
    let descripcion: String
    let precio: String
}

struct PlanPagoView: View {
    @AppStorage("usuarioPagado") var usuarioPagado: Bool = false

    let planes: [Plan] = [
        Plan(nombre: "Prueba gratuita", descripcion: "Acceso limitado a funciones", precio: "$0.00/mes"),
        Plan(nombre: "Donaciones", descripcion: "Acceso limitado a funciones de forma temporal", precio: "$2.50"),
        Plan(nombre: "Premium", descripcion: "Acesso ilimitado a todas las funciones.", precio: "$9.99/mes")
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
                                .foregroundColor(.blue)

                            Spacer()

                            Button(action: {
                                pagar(plan: plan)
                            }) {
                                Text("Pagar Plan")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color("ButtonColor"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
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
            }
        }
    }

    func pagar(plan: Plan) {
        // Aquí puedes agregar lógica de pago real si lo deseas
        usuarioPagado = true
        print("✅ Usuario ha pagado el plan: \(plan.nombre)")
    }
}

#Preview {
    PlanPagoView()
}

