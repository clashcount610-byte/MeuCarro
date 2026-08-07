import SwiftData
import SwiftUI

// MARK: - Container (somente @Query, sem UI de lista)
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var showAddFuel = false
    @State private var showSettings = false

    var body: some View {
        // Passa dados calculados como valores simples para a view de conteúdo
        // Isso quebra o ciclo entre @Query e o container de lista no iOS 26
        let vehicle = vehicles.first
        let monthStats = FuelCalculator.monthStats(fills: fills)
        let series = FuelCalculator.consumptionSeries(fills: fills)
        let avgConsumption: Double? = series.isEmpty ? nil : series.reduce(0) { $0 + $1.kmPerL } / Double(series.count)
        let lastFill = fills.first
        let lastConsumption = series.last?.kmPerL
        let recentTrips = Array(trips.prefix(3))

        DashboardContent(
            vehicleName: vehicle?.name ?? "Meu Carro",
            odometerText: Format.number(vehicle?.odometerKm ?? 0, formatter: Format.decimal1) + " km",
            monthStats: monthStats,
            avgConsumption: avgConsumption,
            lastFill: lastFill,
            lastConsumption: lastConsumption,
            recentTrips: recentTrips,
            showAddFuel: $showAddFuel,
            showSettings: $showSettings
        )
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
}

// MARK: - View de conteúdo (sem @Query, sem @Environment de dados)
private struct DashboardContent: View {
    let vehicleName: String
    let odometerText: String
    let monthStats: FuelCalculator.MonthStats
    let avgConsumption: Double?
    let lastFill: FuelFill?
    let lastConsumption: Double?
    let recentTrips: [Trip]
    @Binding var showAddFuel: Bool
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(vehicleName)
                    .font(.largeTitle.bold())

                groupBox("Odômetro") {
                    Text(odometerText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                groupBox("Resumo do mês") {
                    row("Consumo médio", avgConsumption.map(Format.kmPerL) ?? "—")
                    row("Gasto", Format.money(monthStats.total))
                    row("Custo/km", monthStats.costPerKm.map(Format.moneyPerKm) ?? "—")
                    row("Distância", Format.km(monthStats.distanceKm))
                }

                if let last = lastFill {
                    groupBox("Último abastecimento") {
                        row("Data", Format.dateMedium.string(from: last.date))
                        row("Volume", Format.liters(last.liters))
                        row("Total", Format.money(last.totalCost))
                        if let c = lastConsumption {
                            row("Consumo", Format.kmPerL(c))
                        }
                    }
                }

                if !recentTrips.isEmpty {
                    groupBox("Percursos recentes") {
                        ForEach(recentTrips) { trip in
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
