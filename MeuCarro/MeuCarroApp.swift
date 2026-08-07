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
            print("Erro ao carregar banco persistente: \(error). Tentando modo em memória.")
            do {
                container = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            } catch {
                print("Erro ao carregar modo em memória: \(error). Criando contêiner de contingência.")
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                if let fallback = try? ModelContainer(for: schema, configurations: [fallbackConfig]) {
                    container = fallback
                } else {
                    container = try! ModelContainer(for: Schema([]))
                }
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
