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
        ScrollView {
            VStack(spacing: 16) {
                odometerCard
                quickActions
                statsGrid
                lastFuelCard
                recentTripsSection
            }
            .padding()
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

    // MARK: - Odômetro

    private var odometerCard: some View {
        VStack(spacing: 6) {
            HStack {
                Label("Odômetro", systemImage: "speedometer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(odometerText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()

            Text("km")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var odometerText: String {
        guard let vehicle else { return "0" }
        return Format.number(vehicle.odometerKm, formatter: .decimal1)
    }

    // MARK: - Ações rápidas

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                showAddFuel = true
            } label: {
                quickActionLabel(title: "Abastecer", icon: "fuelpump.fill", color: .green)
            }
            .buttonStyle(.plain)

            NavigationLink {
                TripsView()
            } label: {
                quickActionLabel(title: "Percursos", icon: "mappin.and.ellipse", color: .blue)
            }

            NavigationLink {
                ZeroToHundredView()
            } label: {
                quickActionLabel(title: "0–100 km/h", icon: "gauge.with.dots.needle.67percent", color: .orange)
            }
        }
    }

    private func quickActionLabel(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(Circle().fill(color.opacity(0.15)))
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Estatísticas

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Consumo médio",
                value: averageConsumption.map(Format.kmPerL) ?? "--",
                icon: "gauge.with.dots.needle.50percent",
                color: .blue
            )
            statCard(
                title: "Gasto no mês",
                value: Format.money(monthStats.total),
                icon: "dollarsign.circle.fill",
                color: .green
            )
            statCard(
                title: "Custo por km",
                value: monthStats.costPerKm.map(Format.moneyPerKm) ?? "--",
                icon: "sum",
                color: .orange
            )
            statCard(
                title: "Distância no mês",
                value: Format.km(monthStats.distanceKm),
                icon: "road.lanes",
                color: .purple
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Último abastecimento

    @ViewBuilder
    private var lastFuelCard: some View {
        if let last = fills.first {
            HStack(spacing: 12) {
                Image(systemName: "fuelpump.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.green.opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Último abastecimento")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Format.liters(last.liters)) • \(Format.money(last.totalCost))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(Format.dateMedium.string(from: last.date)) • \(Format.km(last.odometerKm))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let consumption = lastConsumption {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Último consumo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(Format.kmPerL(consumption))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - Percursos recentes

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Percursos recentes")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    TripsView()
                } label: {
                    Text("Ver todos")
                        .font(.subheadline)
                }
            }

            if trips.isEmpty {
                Text("Nenhum percurso registrado. Toque em Percursos para gravar uma viagem.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(trips.prefix(3)) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.title.isEmpty ? "Percurso" : trip.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(Format.dateTimeShort.string(from: trip.startDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Format.km(trip.distanceKm))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("máx \(Format.speed(trip.maxSpeedKmh))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
