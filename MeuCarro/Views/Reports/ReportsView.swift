import Charts
import SwiftData
import SwiftUI

struct ReportsView: View {
    @Query(sort: \FuelFill.date) private var fills: [FuelFill]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @State private var months = 6

    private var monthly: [FuelCalculator.MonthlyTotal] {
        FuelCalculator.monthlyTotals(fills: fills, months: months)
    }

    private var consumptionSeries: [ConsumptionSample] {
        FuelCalculator.consumptionSeries(fills: fills)
    }

    private var tripMonthly: [FuelCalculator.MonthlyTotal] {
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

    private var totalSpend: Double {
        fills.reduce(0) { $0 + $1.totalCost }
    }

    private var totalTripKm: Double {
        trips.reduce(0) { $0 + $1.distanceKm }
    }

    private var averageConsumption: Double? {
        guard !consumptionSeries.isEmpty else { return nil }
        return consumptionSeries.reduce(0) { $0 + $1.kmPerL } / Double(consumptionSeries.count)
    }

    var body: some View {
        ScrollView {
            if fills.isEmpty && trips.isEmpty {
                ContentUnavailableView {
                    Label("Sem dados", systemImage: "chart.bar.xaxis")
                } description: {
                    Text("Registre abastecimentos e percursos para ver os relatórios.")
                }
            } else {
                VStack(spacing: 20) {
                    summaryRow
                    periodPicker
                    spendChartCard
                    costPerKmChartCard
                    consumptionChartCard
                    tripChartCard
                }
                .padding()
            }
        }
        .navigationTitle("Relatórios")
    }

    // MARK: - Resumo

    private var summaryRow: some View {
        HStack(spacing: 12) {
            miniStat(title: "Gasto total", value: Format.money(totalSpend), icon: "dollarsign.circle.fill", color: .green)
            miniStat(title: "Percorrido", value: Format.km(totalTripKm), icon: "mappin.and.ellipse", color: .blue)
            miniStat(title: "Consumo médio", value: averageConsumption.map(Format.kmPerL) ?? "--", icon: "gauge.with.dots.needle.50percent", color: .purple)
        }
    }

    private func miniStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var periodPicker: some View {
        Picker("Período", selection: $months) {
            Text("3 meses").tag(3)
            Text("6 meses").tag(6)
            Text("12 meses").tag(12)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Gráficos

    private var spendChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gasto com combustível")
                .font(.headline)
            Chart(monthly) { item in
                BarMark(
                    x: .value("Mês", item.month, unit: .month),
                    y: .value("Gasto", item.total)
                )
                .foregroundStyle(.green.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .chartCard()
    }

    private var costPerKmChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custo por km")
                .font(.headline)
            Chart(monthly.filter { $0.distanceKm > 0 }) { item in
                LineMark(
                    x: .value("Mês", item.month, unit: .month),
                    y: .value("Custo/km", item.total / item.distanceKm)
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 160)
            .chartYAxisLabel("R$/km", position: .trailing)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .chartCard()
    }

    private var consumptionChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consumo real (tanque cheio)")
                .font(.headline)
            if consumptionSeries.isEmpty {
                Text("Registre pelo menos dois abastecimentos de tanque cheio para calcular o consumo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Chart(consumptionSeries) { sample in
                    LineMark(
                        x: .value("Data", sample.date),
                        y: .value("Consumo", sample.kmPerL)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Data", sample.date),
                        y: .value("Consumo", sample.kmPerL)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 180)
                .chartYAxisLabel("km/L", position: .trailing)
            }
        }
        .chartCard()
    }

    private var tripChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distância percorrida por mês")
                .font(.headline)
            Chart(tripMonthly) { item in
                BarMark(
                    x: .value("Mês", item.month, unit: .month),
                    y: .value("Distância", item.total)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel("km", position: .trailing)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .chartCard()
    }
}

// MARK: - Modificador de cartão

struct ChartCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

extension View {
    func chartCard() -> some View {
        modifier(ChartCard())
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
}
