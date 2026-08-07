import SwiftData
import SwiftUI

struct FuelComparatorView: View {
    @Query private var vehicles: [VehicleInfo]
    @State private var gasPrice = 5.89
    @State private var ethanolPrice = 3.99
    @State private var ratio = 0.7

    private var vehicle: VehicleInfo? { vehicles.first }

    private var result: (recommendation: FuelCalculator.Recommendation, parity: Double, savings: Double) {
        FuelCalculator.compare(gasPrice: gasPrice, ethanolPrice: ethanolPrice, ethanolRatio: ratio)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Comparar gasolina × etanol").font(.headline)

                LabeledContent("Gasolina (R$/L)") {
                    TextField("0", value: $gasPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                LabeledContent("Etanol (R$/L)") {
                    TextField("0", value: $ethanolPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                Text("Rendimento do etanol: \(Int(ratio * 100))%")
                Slider(value: $ratio, in: 0.6...0.9, step: 0.01)

                Divider()

                Text("Recomendação: \(result.recommendation.label)")
                    .font(.title3.bold())
                Text("Paridade: \(Format.money(result.parity))/L")
                if result.savings > 0 {
                    Text(String(format: "Economia estimada: %.1f%%", result.savings))
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .task {
            if let r = vehicle?.ethanolRatio { ratio = r }
        }
    }
}
