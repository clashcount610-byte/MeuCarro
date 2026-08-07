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
            container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            // Tela mínima de diagnóstico: se ISTO crashar, o problema não é a UI do app
            ContentView()
                .modelContainer(container)
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("MeuCarro OK")
            .font(.title)
            .padding()
    }
}
