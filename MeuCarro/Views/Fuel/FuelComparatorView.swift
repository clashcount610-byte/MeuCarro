import SwiftData
import SwiftUI

struct FuelComparatorView: View {
    @Query private var vehicles: [VehicleInfo]
    @State private var gasPrice: Double?
    @State private var ethanolPrice: Double?
    @State private var ratio = 0.75

    private var vehicle: VehicleInfo? { vehicles.first }

    var body: some View {
        Form {
            Section("Preços atuais") {
                TextField("Preço da gasolina (R$)", value: $gasPrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Preço do etanol (R$)", value: $ethanolPrice, format: .number)
                    .keyboardType(.decimalPad)
            }

            Section {
                HStack {
                    Text("Rendimento do etanol")
                    Spacer()
                    Text("\(Int(ratio * 100))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $ratio, in: 0.60...0.90, step: 0.01)
            } header: {
                Text("Rendimento relativo")
            } footer: {
                Text("O etanol rende em média 70–75% da gasolina. Ajuste conforme o seu veículo (Ajustes).")
            }

            Section("Resultado") {
                if let gasPrice, let ethanolPrice, gasPrice > 0, ethanolPrice > 0 {
                    recommendationCard(gasPrice: gasPrice, ethanolPrice: ethanolPrice)
                } else {
                    Text("Informe os dois preços para comparar.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            if let vehicle {
                ratio = vehicle.ethanolRatio
            }
        }
    }

    private func recommendationCard(gasPrice: Double, ethanolPrice: Double) -> some View {
        let comparison = FuelCalculator.compare(
            gasPrice: gasPrice,
            ethanolPrice: ethanolPrice,
            ethanolRatio: ratio
        )
        let isEthanol = comparison.recommendation == .etanol
        let isTie = comparison.recommendation == .tie

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isTie ? "equal.circle.fill" : (isEthanol ? "checkmark.circle.fill" : "xmark.circle.fill"))
                    .foregroundStyle(isEthanol ? .green : (isTie ? .blue : .orange))
                Text("Abasteça com: \(comparison.recommendation.label)")
                    .font(.headline)
                Spacer()
            }

            Text("Preço de equilíbrio (paridade): \(Format.money(comparison.parity))")
                .font(.subheadline)

            Text("O etanol compensa se custar menos que \(Format.money(comparison.parity))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if comparison.savings > 0, !isTie {
                Text("Economia estimada de \(String(format: "%.1f", comparison.savings))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEthanol ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FuelComparatorView()
    }
}
