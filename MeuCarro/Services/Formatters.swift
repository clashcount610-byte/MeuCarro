import Foundation

enum Format {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static let decimal2: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static let decimal1: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    static let dateMedium: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let dateTimeShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "MMM/yyyy"
        return f
    }()

    static func money(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    static func moneyPerKm(_ value: Double) -> String {
        "\(money(value))/km"
    }

    static func number(_ value: Double, formatter: NumberFormatter) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func km(_ value: Double) -> String {
        "\(number(value, formatter: decimal1)) km"
    }

    static func kmPerL(_ value: Double) -> String {
        "\(number(value, formatter: decimal2)) km/L"
    }

    static func liters(_ value: Double) -> String {
        "\(number(value, formatter: decimal2)) L"
    }

    static func pricePerLiter(_ value: Double) -> String {
        "\(number(value, formatter: decimal2))/L"
    }

    static func speed(_ value: Double) -> String {
        "\(number(value, formatter: decimal1)) km/h"
    }

    static func seconds(_ value: TimeInterval) -> String {
        String(format: "%.2f s", value)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(max(interval, 0))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%02ds", s)
    }

    static func stopwatch(_ interval: TimeInterval) -> String {
        let totalCentis = Int((max(interval, 0) * 100).rounded())
        let m = totalCentis / 6000
        let s = (totalCentis % 6000) / 100
        let cs = totalCentis % 100
        return String(format: "%02d:%02d.%02d", m, s, cs)
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }
}
