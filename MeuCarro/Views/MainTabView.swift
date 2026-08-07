import SwiftUI

/// Adia a inicialização da view até o momento em que ela for realmente exibida.
/// Evita o crash recursivo no AttributeGraph do iOS 26 quando várias views
/// com @Query são inicializadas ao mesmo tempo pelo TabView.
private struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) { self.build = build }
    var body: Content { build() }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LazyView(NavigationStack { DashboardView() })
                .tabItem { Label("Início", systemImage: "house.fill") }

            LazyView(NavigationStack { FuelView() })
                .tabItem { Label("Combustível", systemImage: "fuelpump.fill") }

            LazyView(NavigationStack { TripsView() })
                .tabItem { Label("Percursos", systemImage: "map.fill") }

            LazyView(NavigationStack { PerformanceView() })
                .tabItem { Label("Performance", systemImage: "flag.checkered") }

            LazyView(NavigationStack { ReportsView() })
                .tabItem { Label("Relatórios", systemImage: "chart.bar.fill") }
        }
    }
}
