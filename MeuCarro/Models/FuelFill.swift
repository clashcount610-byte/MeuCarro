import Foundation
import SwiftData
import SwiftUI

@Model
final class FuelFill {
    var date: Date
    var liters: Double
    var pricePerLiter: Double
    var totalCost: Double
    var odometerKm: Double
    var isFullTank: Bool
    var fuelTypeRaw: String
    var notes: String

    init(
        date: Date = .now,
        liters: Double = 0,
        pricePerLiter: Double = 0,
        totalCost: Double = 0,
        odometerKm: Double = 0,
        isFullTank: Bool = false,
        fuelTypeRaw: String = "gasolina",
        notes: String = ""
    ) {
        self.date = date
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.totalCost = totalCost
        self.odometerKm = odometerKm
        self.isFullTank = isFullTank
        self.fuelTypeRaw = fuelTypeRaw
        self.notes = notes
    }

    var fuelType: FuelType { FuelType(rawValue: fuelTypeRaw) ?? .gasolina }
}
