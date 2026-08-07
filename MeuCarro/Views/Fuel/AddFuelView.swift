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

    private var vehicle: VehicleInfo? { vehicles.first }

    private var totalCost: Double { liters * pricePerLiter }

    private var consumptionPreview: Double? {
        guard isFullTank, liters > 0,
              let previous = fills.first(where: { $0.isFullTank }),
              odometer > previous.odometerKm else { return nil }
        return FuelCalculator.kmPerL(distanceKm: odometer - previous.odometerKm, liters: liters)
    }

    private var isValid: Bool { liters > 0 && pricePerLiter > 0 && odometer >= 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DatePicker("Data", selection: $date)
                field("Odômetro (km)", value: $odometer)
                field("Litros", value: $liters)
                field("Preço por litro (R$)", value: $pricePerLiter)

                if totalCost > 0 {
                    LabeledContent("Total") {
                        Text(Format.money(totalCost)).fontWeight(.semibold)
                    }
                }

                Picker("Combustível", selection: $fuelType) {
                    ForEach(FuelType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                Toggle("Tanque cheio", isOn: $isFullTank)

                if let c = consumptionPreview {
                    Text("Consumo estimado: \(Format.kmPerL(c))")
                        .foregroundStyle(.blue)
                }

                Button("Salvar") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Novo abastecimento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
        }
        .onAppear {
            odometer = vehicle?.odometerKm ?? 0
            fuelType = vehicle?.fuelType ?? .gasolina
        }
    }

    private func field(_ title: String, value: Binding<Double>) -> some View {
        LabeledContent(title) {
            TextField("0", value: value, format: .number.precision(.fractionLength(2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
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
            fuelTypeRaw: fuelType.rawValue
        )
        context.insert(fill)
        if let vehicle, odometer > vehicle.odometerKm {
            vehicle.odometerKm = odometer
        } else if vehicle == nil {
            let v = VehicleInfo(odometerKm: odometer, fuelTypeRaw: fuelType.rawValue)
            context.insert(v)
        }
        try? context.save()
        dismiss()
    }
}
