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
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(vehicle?.name ?? "Meu Carro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
                .padding()

                // Odometer card
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
                .padding(.horizontal)

                // Quick actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ações rápidas")
                        .font(.headline)
                    
                    Button {
                        showAddFuel = true
                    } label: {
                        Label("Registrar abastecimento", systemImage: "fuelpump.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showTrips = true
                    } label: {
                        Label("Ver percursos", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showZeroToHundred = true
                    } label: {
                        Label("Teste 0–100 km/h", systemImage: "gauge.with.dots.needle.67percent")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estatísticas")
                        .font(.headline)
                    
                    statRow(title: "Consumo médio", value: averageConsumption.map(Format.kmPerL) ?? "--", icon: "gauge.with.dots.needle.50percent")
                    statRow(title: "Gasto no mês", value: Format.money(monthStats.total), icon: "dollarsign.circle.fill")
                    statRow(title: "Custo por km", value: monthStats.costPerKm.map(Format.moneyPerKm) ?? "--", icon: "sum")
                    statRow(title: "Distância no mês", value: Format.km(monthStats.distanceKm), icon: "road.lanes")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)

                // Last fill
                if let last = fills.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Último abastecimento")
                            .font(.headline)
                        
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
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top)
                }

                // Recent trips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Percursos recentes")
                        .font(.headline)
                    
                    if trips.isEmpty {
                        Text("Nenhum percurso registrado.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(trips.prefix(3)) { trip in
                            Button {
                                selectedTrip = trip
                            } label: {
                                HStack {
                                    Label(Format.km(trip.distanceKm), systemImage: "mappin.and.ellipse")
                                    Spacer()
                                    Text(Format.dateTimeShort.string(from: trip.startDate))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)

                Spacer(minLength: 20)
            }
        }
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
