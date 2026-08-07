import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var showAddFuel = false
    @State private var showSettings = false

    private var vehicle: VehicleInfo? { vehicles.first }
    private var monthStats: FuelCalculator.MonthStats { FuelCalculator.monthStats(fills: fills) }
    private var series: [ConsumptionSample] { FuelCalculator.consumptionSeries(fills: fills) }
    private var avgConsumption: Double? {
        guard !series.isEmpty else { return nil }
        return series.reduce(0) { $0 + $1.kmPerL } / Double(series.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(vehicle?.name ?? "Meu Carro")
                    .font(.largeTitle.bold())

                groupBox("Odômetro") {
                    Text(odometerText + " km")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                groupBox("Resumo do mês") {
                    row("Consumo médio", avgConsumption.map(Format.kmPerL) ?? "—")
                    row("Gasto", Format.money(monthStats.total))
                    row("Custo/km", monthStats.costPerKm.map(Format.moneyPerKm) ?? "—")
                    row("Distância", Format.km(monthStats.distanceKm))
                }

                if let last = fills.first {
                    groupBox("Último abastecimento") {
                        row("Data", Format.dateMedium.string(from: last.date))
                        row("Volume", Format.liters(last.liters))
                        row("Total", Format.money(last.totalCost))
                        if let c = series.last?.kmPerL {
                            row("Consumo", Format.kmPerL(c))
                        }
                    }
                }

                if !trips.isEmpty {
                    groupBox("Percursos recentes") {
                        ForEach(Array(trips.prefix(3))) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                HStack {
                                    Text(Format.km(trip.distanceKm))
                                    Spacer()
                                    Text(Format.dateTimeShort.string(from: trip.startDate))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Button("Registrar abastecimento") { showAddFuel = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Início")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ajustes") { showSettings = true }
            }
        }
        .sheet(isPresented: $showAddFuel) {
            NavigationStack { AddFuelView() }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .onAppear {
            if vehicles.isEmpty {
                context.insert(VehicleInfo())
                try? context.save()
            }
        }
    }

    private var odometerText: String {
        Format.number(vehicle?.odometerKm ?? 0, formatter: Format.decimal1)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }

    private func groupBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
