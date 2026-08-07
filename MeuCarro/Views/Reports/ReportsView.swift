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
        List {
            if fills.isEmpty && trips.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Sem dados", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Registre abastecimentos e percursos para ver os relatórios.")
                    }
                }
            } else {
                Section("Resumo") {
                    HStack {
                        Label("Gasto total", systemImage: "dollarsign.circle.fill")
                        Spacer()
                        Text(Format.money(totalSpend)).fontWeight(.semibold)
                    }
                    HStack {
                        Label("Percorrido", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text(Format.km(totalTripKm)).fontWeight(.semibold)
                    }
                    HStack {
                        Label("Consumo médio", systemImage: "gauge.with.dots.needle.50percent")
                        Spacer()
                        Text(averageConsumption.map(Format.kmPerL) ?? "--").fontWeight(.semibold)
                    }
                }

                Section("Período") {
                    Picker("Período", selection: $months) {
                        Text("3 meses").tag(3)
                        Text("6 meses").tag(6)
                        Text("12 meses").tag(12)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Gasto com combustível") {
                    chartContainer {
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
                }

                Section("Custo por km") {
                    chartContainer {
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
                }

                Section("Consumo real (tanque cheio)") {
                    if consumptionSeries.isEmpty {
                        Text("Registre pelo menos dois abastecimentos de tanque cheio para calcular o consumo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        chartContainer {
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
                }

                Section("Distância percorrida por mês") {
                    chartContainer {
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
                }
            }
        }
        .navigationTitle("Relatórios")
    }

    private func chartContainer<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .frame(maxWidth: .infinity)
    }

#Preview {
    NavigationStack {
        ReportsView()
    }
}
