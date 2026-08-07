import Charts
import SwiftData
import SwiftUI

// MARK: - Container (somente @Query)
struct ReportsView: View {
    @Query(sort: \FuelFill.date) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @State private var months = 6

    var body: some View {
        let monthly = FuelCalculator.monthlyTotals(fills: fills, months: months)
        let consumptionSeries = FuelCalculator.consumptionSeries(fills: fills)
        let tripMonthly = buildTripMonthly()
        let totalSpend = fills.reduce(0) { $0 + $1.totalCost }
        let totalTripKm = trips.reduce(0) { $0 + $1.distanceKm }
        let averageConsumption: Double? = consumptionSeries.isEmpty ? nil :
            consumptionSeries.reduce(0) { $0 + $1.kmPerL } / Double(consumptionSeries.count)

        ReportsContent(
            months: $months,
            isEmpty: fills.isEmpty && trips.isEmpty,
            monthly: monthly,
            consumptionSeries: consumptionSeries,
            tripMonthly: tripMonthly,
            totalSpend: totalSpend,
            totalTripKm: totalTripKm,
            averageConsumption: averageConsumption
        )
        .navigationTitle("Relatórios")
    }

    private func buildTripMonthly() -> [FuelCalculator.MonthlyTotal] {
        let calendar = Calendar.current
        let now = Date.now
        var result: [FuelCalculator.MonthlyTotal] = []
        for offset in (0..<months).reversed() {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .month, for: month) else { continue }
            let km = trips
                .filter { interval.contains($0.startDate) }
                .reduce(0) { $0 + $1.distanceKm }
            result.append(FuelCalculator.MonthlyTotal(month: interval.start, total: km, distanceKm: km))
        }
        return result
    }
}

// MARK: - View de conteúdo (sem @Query)
private struct ReportsContent: View {
    @Binding var months: Int
    let isEmpty: Bool
    let monthly: [FuelCalculator.MonthlyTotal]
    let consumptionSeries: [ConsumptionSample]
    let tripMonthly: [FuelCalculator.MonthlyTotal]
    let totalSpend: Double
    let totalTripKm: Double
    let averageConsumption: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEmpty {
                    Text("Sem dados ainda. Registre abastecimentos e percursos.")
                        .foregroundStyle(.secondary)
                } else {
                    group("Resumo") {
                        row("Gasto total", Format.money(totalSpend))
                        row("Percorrido", Format.km(totalTripKm))
                        row("Consumo médio", averageConsumption.map(Format.kmPerL) ?? "—")
                    }

                    Picker("Período", selection: $months) {
                        Text("3 m").tag(3)
                        Text("6 m").tag(6)
                        Text("12 m").tag(12)
                    }
                    .pickerStyle(.segmented)

                    group("Gasto com combustível") {
                        Chart(monthly) { item in
                            BarMark(
                                x: .value("Mês", item.month, unit: .month),
                                y: .value("Gasto", item.total)
                            )
                        }
                        .frame(height: 180)
                    }

                    group("Consumo (tanque cheio)") {
                        if consumptionSeries.isEmpty {
                            Text("Precisa de 2+ tanques cheios.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Chart(consumptionSeries) { sample in
                                LineMark(
                                    x: .value("Data", sample.date),
                                    y: .value("km/L", sample.kmPerL)
                                )
                            }
                            .frame(height: 160)
                        }
                    }

                    group("Distância por mês") {
                        Chart(tripMonthly) { item in
                            BarMark(
                                x: .value("Mês", item.month, unit: .month),
                                y: .value("km", item.total)
                            )
                        }
                        .frame(height: 160)
                    }
                }
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
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
