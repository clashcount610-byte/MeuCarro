import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @AppStorage("appearance") private var appearance = "system"
    @State private var confirmClear = false

    private var vehicle: VehicleInfo? { vehicles.first }

    var body: some View {
        Form {
            Section {
                TextField("Nome", text: nameBinding)
                HStack {
                    Text("Odômetro (km)")
                    Spacer()
                    TextField("0", value: odometerBinding, format: FloatingPointFormatStyle<Double>.number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }
                Picker("Combustível", selection: fuelTypeBinding) {
                    ForEach(VehicleInfo.allFuelTypes) { type in
                        Text(type.label).tag(type)
                    }
                }
                HStack {
                    Text("Rendimento do etanol")
                    Spacer()
                    Text("\(Int((vehicle?.ethanolRatio ?? 0.75) * 100))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: ratioBinding, in: 0.60...0.90, step: 0.01)
            } header: {
                Text("Veículo")
            } footer: {
                Text("O odômetro é atualizado automaticamente a cada percurso registrado.")
            }

            Section("Aparência") {
                Picker("Tema", selection: $appearance) {
                    Text("Sistema").tag("system")
                    Text("Claro").tag("light")
                    Text("Escuro").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("Dados") {
                Button("Carregar dados de exemplo") {
                    loadSampleData()
                }
                Button("Apagar todos os dados", role: .destructive) {
                    confirmClear = true
                }
            }

            Section {
                Text("Dados armazenados localmente no dispositivo (SwiftData).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Versão 1.0")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Apagar todos os dados?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Apagar tudo", role: .destructive) {
                clearAll()
            }
        }
        .onAppear {
            if vehicles.isEmpty {
                context.insert(VehicleInfo())
            }
        }
    }

    // MARK: - Bindings

    private var nameBinding: Binding<String> {
        Binding(
            get: { vehicle?.name ?? "" },
            set: { vehicle?.name = $0 }
        )
    }

    private var odometerBinding: Binding<Double> {
        Binding(
            get: { vehicle?.odometerKm ?? 0 },
            set: { vehicle?.odometerKm = $0 }
        )
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

    // MARK: - Dados

    private func clearAll() {
        try? context.delete(model: FuelFill.self)
        try? context.delete(model: Trip.self)
        try? context.delete(model: PerformanceRun.self)
        try? context.save()
    }

    private func loadSampleData() {
        let calendar = Calendar.current
        let vehicle = self.vehicle ?? {
            let v = VehicleInfo(name: "Meu Carro", odometerKm: 24_000)
            context.insert(v)
            return v
        }()

        var odometer = vehicle.odometerKm
        var date = calendar.date(byAdding: .month, value: -6, to: .now) ?? .now

        for i in 0..<24 {
            let liters = [42.0, 38.0, 45.0, 40.0][i % 4]
            let price = 5.6 + Double(i % 3) * 0.15
            odometer += 480 + Double((i * 37) % 120)
            context.insert(FuelFill(
                date: date,
                liters: liters,
                pricePerLiter: price,
                totalCost: liters * price,
                odometerKm: odometer,
                isFullTank: true,
                fuelTypeRaw: FuelType.gasolina.rawValue
            ))
            date = calendar.date(byAdding: .day, value: 8, to: date) ?? date
        }
        vehicle.odometerKm = odometer

        var tripDate = calendar.date(byAdding: .day, value: -3, to: .now) ?? .now
        let starts = [
            (lat: -23.5505, lon: -46.6333),
            (lat: -23.5600, lon: -46.6500)
        ]
        for (i, start) in starts.enumerated() {
            var points: [TripPoint] = []
            for step in 0..<60 {
                points.append(TripPoint(
                    latitude: start.lat + Double(step) * 0.0003,
                    longitude: start.lon + Double(step) * 0.0004,
                    timestamp: tripDate.addingTimeInterval(Double(step) * 5),
                    speed: 40 + sin(Double(step) / 6) * 30 + Double(step) * 0.4,
                    altitude: 750
                ))
            }
            context.insert(Trip(
                startDate: tripDate,
                endDate: tripDate.addingTimeInterval(300),
                distanceKm: 4.5 + Double(i) * 3.2,
                maxSpeedKmh: 88 + Double(i * 6),
                avgSpeedKmh: 54,
                title: "Percurso de exemplo \(i + 1)",
                points: points
            ))
            tripDate = calendar.date(byAdding: .day, value: -10, to: tripDate) ?? tripDate
        }

        context.insert(PerformanceRun(typeRaw: PerformanceType.zeroToHundred.rawValue, duration: 9.8, maxSpeedKmh: 101))
        context.insert(PerformanceRun(typeRaw: PerformanceType.coldStart.rawValue, duration: 2.4))

        try? context.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
