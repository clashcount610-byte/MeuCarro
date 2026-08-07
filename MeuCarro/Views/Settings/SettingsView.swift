import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @AppStorage("appearance") private var appearance = "system"
    @State private var confirmClear = false

    private var vehicle: VehicleInfo? { vehicles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                group("Veículo") {
                    TextField("Nome", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                    LabeledContent("Odômetro (km)") {
                        TextField("0", value: odometerBinding, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Picker("Combustível", selection: fuelTypeBinding) {
                        ForEach(VehicleInfo.allFuelTypes) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    Text("Rendimento etanol: \(Int((vehicle?.ethanolRatio ?? 0.75) * 100))%")
                    Slider(value: ratioBinding, in: 0.60...0.90, step: 0.01)
                }

                group("Aparência") {
                    Picker("Tema", selection: $appearance) {
                        Text("Sistema").tag("system")
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    Text("O tema será reativado com segurança em breve.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                group("Dados") {
                    Button("Carregar dados de exemplo") { loadSampleData() }
                    Button("Apagar todos os dados", role: .destructive) { confirmClear = true }
                }

                Text("Versão 1.0 · dados locais (SwiftData)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Apagar todos os dados?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Apagar tudo", role: .destructive) { clearAll() }
        }
        .onAppear { ensureVehicle() }
    }

    private func ensureVehicle() {
        if vehicles.isEmpty {
            context.insert(VehicleInfo())
            try? context.save()
        }
    }

    private var nameBinding: Binding<String> {
        Binding(get: { vehicle?.name ?? "" }, set: { vehicle?.name = $0 })
    }

    private var odometerBinding: Binding<Double> {
        Binding(get: { vehicle?.odometerKm ?? 0 }, set: { vehicle?.odometerKm = $0 })
    }

    private var fuelTypeBinding: Binding<FuelType> {
        Binding(
            get: { vehicle?.fuelType ?? .flex },
            set: { vehicle?.fuelTypeRaw = $0.rawValue }
        )
    }

    private var ratioBinding: Binding<Double> {
        Binding(
            get: { vehicle?.ethanolRatio ?? 0.75 },
            set: { vehicle?.ethanolRatio = $0 }
        )
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func clearAll() {
        try? context.delete(model: FuelFill.self)
        try? context.delete(model: Trip.self)
        try? context.delete(model: PerformanceRun.self)
        try? context.save()
    }

    private func loadSampleData() {
        ensureVehicle()
        let calendar = Calendar.current
        guard let vehicle else { return }
        var odometer = max(vehicle.odometerKm, 24_000)
        var date = calendar.date(byAdding: .month, value: -6, to: .now) ?? .now

        for i in 0..<12 {
            let liters = [40.0, 38.0, 42.0, 45.0][i % 4]
            let price = 5.6 + Double(i % 3) * 0.12
            odometer += 450 + Double((i * 17) % 80)
            context.insert(FuelFill(
                date: date,
                liters: liters,
                pricePerLiter: price,
                totalCost: liters * price,
                odometerKm: odometer,
                isFullTank: true,
                fuelTypeRaw: FuelType.gasolina.rawValue
            ))
            date = calendar.date(byAdding: .day, value: 14, to: date) ?? date
        }
        vehicle.odometerKm = odometer

        var tripDate = calendar.date(byAdding: .day, value: -2, to: .now) ?? .now
        for i in 0..<2 {
            var points: [TripPoint] = []
            let baseLat = -23.55 + Double(i) * 0.01
            let baseLon = -46.63
            for step in 0..<40 {
                points.append(TripPoint(
                    latitude: baseLat + Double(step) * 0.00025,
                    longitude: baseLon + Double(step) * 0.0003,
                    timestamp: tripDate.addingTimeInterval(Double(step) * 8),
                    speed: 35 + Double(step % 20),
                    altitude: 750
                ))
            }
            context.insert(Trip(
                startDate: tripDate,
                endDate: tripDate.addingTimeInterval(320),
                distanceKm: 5.2 + Double(i) * 2.1,
                maxSpeedKmh: 82 + Double(i * 5),
                avgSpeedKmh: 48,
                title: "Percurso exemplo \(i + 1)",
                points: points
            ))
            tripDate = calendar.date(byAdding: .day, value: -5, to: tripDate) ?? tripDate
        }

        context.insert(PerformanceRun(typeRaw: PerformanceType.zeroToHundred.rawValue, duration: 9.8, maxSpeedKmh: 102))
        context.insert(PerformanceRun(typeRaw: PerformanceType.coldStart.rawValue, duration: 2.3))
        try? context.save()
    }
}
