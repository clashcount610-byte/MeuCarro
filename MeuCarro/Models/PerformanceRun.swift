import Foundation
import SwiftData
import SwiftUI

@Model
final class PerformanceRun {
    var date: Date
    var typeRaw: String
    var duration: TimeInterval
    var maxSpeedKmh: Double

    init(
        date: Date = .now,
        typeRaw: String,
        duration: TimeInterval,
        maxSpeedKmh: Double = 0
    ) {
        self.date = date
        self.typeRaw = typeRaw
        self.duration = duration
        self.maxSpeedKmh = maxSpeedKmh
    }

    var type: PerformanceType { PerformanceType(rawValue: typeRaw) ?? .zeroToHundred }
}

enum PerformanceType: String, CaseIterable, Identifiable {
    case zeroToHundred = "zeroToHundred"
    case coldStart = "coldStart"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .zeroToHundred: "0–100 km/h"
        case .coldStart: "Cold Start"
        }
    }

    var icon: String {
        switch self {
        case .zeroToHundred: "gauge.with.dots.needle.67percent"
        case .coldStart: "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .zeroToHundred: .orange
        case .coldStart: .purple
        }
    }
}
