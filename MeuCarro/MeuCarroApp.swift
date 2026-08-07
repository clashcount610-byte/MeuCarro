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
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            print("Erro ao carregar banco de dados persistente: \(error). Tentando contêiner em memória.")
            do {
                container = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            } catch {
                fatalError("Falha crítica ao inicializar o ModelContainer do SwiftData: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
        }
    }
}
