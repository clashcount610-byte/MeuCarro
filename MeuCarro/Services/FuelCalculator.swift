import Foundation

struct ConsumptionSample: Identifiable {
    let id = UUID()
    let date: Date
    let kmPerL: Double
    let liters: Double
}

enum FuelCalculator {

    static func kmPerL(distanceKm: Double, liters: Double) -> Double? {
        guard distanceKm > 0, liters > 0 else { return nil }
        return distanceKm / liters
    }

    static func costPerKm(totalCost: Double, distanceKm: Double) -> Double? {
        guard distanceKm > 0 else { return nil }
        return totalCost / distanceKm
    }

    /// Consumo real (km/L) entre dois abastecimentos de tanque cheio (método do tanque cheio).
    static func consumption(between previous: FuelFill, and current: FuelFill) -> Double? {
        guard previous.isFullTank, current.isFullTank else { return nil }
        let km = current.odometerKm - previous.odometerKm
        return kmPerL(distanceKm: km, liters: current.liters)
    }

    static func consumptionSeries(fills: [FuelFill]) -> [ConsumptionSample] {
        let fullFills = fills
            .filter { $0.isFullTank }
            .sorted { $0.date < $1.date }

        var samples: [ConsumptionSample] = []
        for i in 1..<fullFills.count {
            let previous = fullFills[i - 1]
            let current = fullFills[i]
            if let value = consumption(between: previous, and: current) {
                samples.append(ConsumptionSample(date: current.date, kmPerL: value, liters: current.liters))
            }
        }
        return samples
    }

    struct MonthStats {
        var total: Double = 0
        var distanceKm: Double = 0

        var costPerKm: Double? {
            FuelCalculator.costPerKm(totalCost: total, distanceKm: distanceKm)
        }
    }

    static func monthStats(fills: [FuelFill], for date: Date = .now) -> MonthStats {
        guard let month = Calendar.current.dateInterval(of: .month, for: date) else { return MonthStats() }
        let inMonth = fills.filter { month.contains($0.date) }
        guard !inMonth.isEmpty else { return MonthStats() }

        let total = inMonth.reduce(0) { $0 + $1.totalCost }
        let odometers: [Double] = inMonth.map(\.odometerKm)
        let distance = (odometers.max() ?? 0) - (odometers.min() ?? 0)
        return MonthStats(total: total, distanceKm: max(distance, 0))
    }

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: Date
        let total: Double
        let distanceKm: Double
    }

    static func monthlyTotals(fills: [FuelFill], months: Int = 6) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let now = Date.now
        return (0..<months).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .month, for: month) else { return nil }
            let inMonth = fills.filter { interval.contains($0.date) }
            let total = inMonth.reduce(0) { $0 + $1.totalCost }
            let odometers = inMonth.map(\.odometerKm)
            let distance = max((odometers.max() ?? 0) - (odometers.min() ?? 0), 0)
            return MonthlyTotal(month: interval.start, total: total, distanceKm: distance)
        }
    }

    enum Recommendation {
        case gasolina
        case etanol
        case tie

        var label: String {
            switch self {
            case .gasolina: "Gasolina"
            case .etanol: "Etanol"
            case .tie: "Empate técnico"
            }
        }
    }

    /// Compara gasolina vs etanol considerando o rendimento relativo do etanol (ex.: 0,75).
    static func compare(
        gasPrice: Double,
        ethanolPrice: Double,
        ethanolRatio: Double
    ) -> (recommendation: Recommendation, parity: Double, savings: Double) {
        guard gasPrice > 0, ethanolPrice > 0 else {
            return (.gasolina, 0, 0)
        }
        let parity = gasPrice * ethanolRatio
        let recommendation: Recommendation
        let savings: Double
        if ethanolPrice < parity - 0.001 {
            recommendation = .etanol
            savings = (1 - ethanolPrice / parity) * 100
        } else if ethanolPrice > parity + 0.001 {
            recommendation = .gasolina
            savings = (1 - parity / ethanolPrice) * 100
        } else {
            recommendation = .tie
            savings = 0
        }
        return (recommendation, parity, savings)
    }
}
