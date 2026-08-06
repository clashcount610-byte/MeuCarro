import SwiftData
import SwiftUI

@main
struct MeuCarroApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            VehicleInfo.self,
            FuelFill.self,
            Trip.self,
            PerformanceRun.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Falha ao criar o container do SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
