import SwiftData
import SwiftUI

struct AddFuelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]

    @State private var date = Date.now
    @State private var odometer = 0.0
    @State private var liters = 0.0
    @State private var pricePerLiter = 0.0
    @State private var isFullTank = true
    @State private var fuelType: FuelType = .gasolina
    @State private var notes = ""

    private var vehicle: VehicleInfo? { vehicles.first }

    private var totalCost: Double {
        liters * pricePerLiter
    }

    private var consumptionPreview: Double? {
        guard isFullTank,
              liters > 0,
              let previous = fills.first(where: { $0.isFullTank }),
              odometer > previous.odometerKm else { return nil }
        return FuelCalculator.kmPerL(distanceKm: odometer - previous.odometerKm, liters: liters)
    }

    private var isValid: Bool {
        liters > 0 && pricePerLiter > 0 && odometer >= 0
    }

    var body: some View {
        Form {
            Section("Dados do abastecimento") {
                DatePicker("Data", selection: $date, displayedComponents: [.date, .hourAndMinute])

                HStack {
                    Text("Odômetro (km)")
                    Spacer()
                    TextField("0", value: $odometer, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }

                HStack {
                    Text("Litros")
                    Spacer()
                    TextField("0", value: $liters, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }

                HStack {
                    Text("Preço por litro (R$)")
                    Spacer()
                    TextField("0", value: $pricePerLiter, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }

                if totalCost > 0 {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(Format.money(totalCost))
                            .fontWeight(.semibold)
                    }
                }

                Picker("Combustível", selection: $fuelType) {
                    ForEach(FuelType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }

                Toggle("Tanque cheio", isOn: $isFullTank)

                if isFullTank {
                    Text("Marque quando encher o tanque até o limite: é assim que o consumo real é calculado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let consumption = consumptionPreview {
                Section("Consumo estimado") {
                    HStack {
                        Label("Desde o último tanque cheio", systemImage: "gauge.with.dots.needle.50percent")
                        Spacer()
                        Text(Format.kmPerL(consumption))
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Text("Salvar abastecimento")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Novo abastecimento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") {
                    dismiss()
                }
            }
        }
        .onAppear {
            odometer = vehicle?.odometerKm ?? 0
            fuelType = vehicle?.fuelType ?? .gasolina
        }
    }

    private func save() {
        let fill = FuelFill(
            date: date,
            liters: liters,
            pricePerLiter: pricePerLiter,
            totalCost: totalCost,
            odometerKm: odometer,
            isFullTank: isFullTank,
            fuelTypeRaw: fuelType.rawValue,
            notes: notes
        )
        context.insert(fill)
        if let vehicle, odometer > vehicle.odometerKm {
            vehicle.odometerKm = odometer
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddFuelView()
    }
}
