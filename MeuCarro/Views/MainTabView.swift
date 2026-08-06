import SwiftUI

struct MainTabView: View {
    @AppStorage("appearance") private var appearance = "system"

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
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}

#Preview {
    MainTabView()
}
