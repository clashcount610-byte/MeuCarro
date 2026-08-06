import Foundation
import SwiftData
import SwiftUI

@Model
final class VehicleInfo {
    var name: String
    var odometerKm: Double
    var fuelTypeRaw: String
    var ethanolRatio: Double
    var createdAt: Date

    init(
        name: String = "Meu Carro",
        odometerKm: Double = 0,
        fuelTypeRaw: String = "flex",
        ethanolRatio: Double = 0.75,
        createdAt: Date = .now
    ) {
        self.name = name
        self.odometerKm = odometerKm
        self.fuelTypeRaw = fuelTypeRaw
        self.ethanolRatio = ethanolRatio
        self.createdAt = createdAt
    }

    var fuelType: FuelType { FuelType(rawValue: fuelTypeRaw) ?? .flex }

    static let allFuelTypes: [FuelType] = [.flex, .gasolina, .etanol, .diesel]
}

enum FuelType: String, CaseIterable, Identifiable {
    case flex, gasolina, etanol, diesel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flex: "Flex"
        case .gasolina: "Gasolina"
        case .etanol: "Etanol"
        case .diesel: "Diesel"
        }
    }

    var icon: String {
        switch self {
        case .flex: "leaf.fill"
        case .gasolina: "drop.fill"
        case .etanol: "aqi.medium"
        case .diesel: "fuelpump.fill"
        }
    }

    var color: Color {
        switch self {
        case .flex: .blue
        case .gasolina: .green
        case .etanol: .yellow
        case .diesel: .brown
        }
    }
}
