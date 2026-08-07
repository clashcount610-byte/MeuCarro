import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Início", systemImage: "house.fill") }

            NavigationStack { FuelView() }
                .tabItem { Label("Combustível", systemImage: "fuelpump.fill") }

            NavigationStack { TripsView() }
                .tabItem { Label("Percursos", systemImage: "map.fill") }

            NavigationStack { PerformanceView() }
                .tabItem { Label("Performance", systemImage: "flag.checkered") }

            NavigationStack { ReportsView() }
                .tabItem { Label("Relatórios", systemImage: "chart.bar.fill") }
        }
    }
}
