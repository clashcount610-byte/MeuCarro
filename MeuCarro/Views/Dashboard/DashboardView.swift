import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showAddFuel = false

    private var vehicle: VehicleInfo? { vehicles.first }

    private var monthStats: FuelCalculator.MonthStats {
        FuelCalculator.monthStats(fills: fills)
    }

    private var consumptionSeries: [ConsumptionSample] {
        FuelCalculator.consumptionSeries(fills: fills)
    }

    private var lastConsumption: Double? { consumptionSeries.last?.kmPerL }

    private var averageConsumption: Double? {
        guard !consumptionSeries.isEmpty else { return nil }
        return consumptionSeries.reduce(0) { $0 + $1.kmPerL } / Double(consumptionSeries.count)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Odômetro", systemImage: "speedometer")
                    Spacer()
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                Text(odometerText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } header: {
                Text(vehicle?.name ?? "Meu Carro")
            }

            Section("Ações rápidas") {
                Button {
                    showAddFuel = true
                } label: {
                    Label("Registrar abastecimento", systemImage: "fuelpump.fill")
                }
                NavigationLink {
                    TripsView()
                } label: {
                    Label("Ver percursos", systemImage: "mappin.and.ellipse")
                }
                NavigationLink {
                    ZeroToHundredView()
                } label: {
                    Label("Teste 0–100 km/h", systemImage: "gauge.with.dots.needle.67percent")
                }
            }

            Section("Estatísticas") {
                statRow(title: "Consumo médio", value: averageConsumption.map(Format.kmPerL) ?? "--", icon: "gauge.with.dots.needle.50percent")
                statRow(title: "Gasto no mês", value: Format.money(monthStats.total), icon: "dollarsign.circle.fill")
                statRow(title: "Custo por km", value: monthStats.costPerKm.map(Format.moneyPerKm) ?? "--", icon: "sum")
                statRow(title: "Distância no mês", value: Format.km(monthStats.distanceKm), icon: "road.lanes")
            }

            if let last = fills.first {
                Section("Último abastecimento") {
                    HStack {
                        Label("\(Format.liters(last.liters)) • \(Format.money(last.totalCost))", systemImage: "fuelpump.fill")
                        Spacer()
                        if let consumption = lastConsumption {
                            Text(Format.kmPerL(consumption))
                                .fontWeight(.semibold)
                        }
                    }
                    Text("\(Format.dateMedium.string(from: last.date)) • \(Format.km(last.odometerKm))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Percursos recentes") {
                if trips.isEmpty {
                    Text("Nenhum percurso registrado.")
                        .foregroundStyle(.secondary)
                }
                ForEach(trips.prefix(3)) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        HStack {
                            Label(Format.km(trip.distanceKm), systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(Format.dateTimeShort.string(from: trip.startDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(vehicle?.name ?? "Meu Carro")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showAddFuel) {
            NavigationStack { AddFuelView() }
        }
    }

    private var odometerText: String {
        guard let vehicle else { return "0" }
        return Format.number(vehicle.odometerKm, formatter: Format.decimal1)
    }

    private func statRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
