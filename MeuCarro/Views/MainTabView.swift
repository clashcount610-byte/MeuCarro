import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Início", systemImage: "gauge.with.dots.needle.50percent") }

            NavigationStack {
                FuelView()
            }
            .tabItem { Label("Combustível", systemImage: "fuelpump.fill") }

            NavigationStack {
                TripsView()
            }
            .tabItem { Label("Percursos", systemImage: "mappin.and.ellipse") }

            NavigationStack {
                PerformanceView()
            }
            .tabItem { Label("Performance", systemImage: "speedometer") }

            NavigationStack {
                ReportsView()
            }
            .tabItem { Label("Relatórios", systemImage: "chart.bar.xaxis") }
        }
    }
}

#Preview {
    MainTabView()
}
