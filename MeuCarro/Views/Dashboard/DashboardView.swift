import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var showAddFuel = false
    @State private var showSettings = false
    @State private var showTrips = false
    @State private var showZeroToHundred = false
    @State private var selectedTrip: Trip?

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
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(vehicle?.name ?? "Meu Carro")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            // Odometer
            VStack(alignment: .leading, spacing: 8) {
                Label("Odômetro", systemImage: "speedometer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(odometerText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Quick actions
            VStack(spacing: 12) {
                Button {
                    showAddFuel = true
                } label: {
                    Label("Registrar abastecimento", systemImage: "fuelpump.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showTrips = true
                } label: {
                    Label("Ver percursos", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    showZeroToHundred = true
                } label: {
                    Label("Teste 0–100 km/h", systemImage: "gauge.with.dots.needle.67percent")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Estatísticas")
                    .font(.headline)
                
                statRow(title: "Consumo médio", value: averageConsumption.map(Format.kmPerL) ?? "--", icon: "gauge.with.dots.needle.50percent")
                statRow(title: "Gasto no mês", value: Format.money(monthStats.total), icon: "dollarsign.circle.fill")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .sheet(isPresented: $showAddFuel) {
            NavigationStack { AddFuelView() }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: $showTrips) {
            NavigationStack { TripsView() }
        }
        .sheet(isPresented: $showZeroToHundred) {
            NavigationStack { ZeroToHundredView() }
        }
        .sheet(item: $selectedTrip) { trip in
            NavigationStack { TripDetailView(trip: trip) }
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
