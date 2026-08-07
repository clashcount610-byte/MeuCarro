import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Conteúdo: apenas a aba selecionada é renderizada
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack { DashboardView() }
                case 1:
                    NavigationStack { FuelView() }
                case 2:
                    NavigationStack { TripsView() }
                case 3:
                    NavigationStack { PerformanceView() }
                case 4:
                    NavigationStack { ReportsView() }
                default:
                    NavigationStack { DashboardView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Tab bar manual
            HStack(spacing: 0) {
                tabButton(index: 0, icon: "house.fill",      label: "Início")
                tabButton(index: 1, icon: "fuelpump.fill",   label: "Combustível")
                tabButton(index: 2, icon: "map.fill",        label: "Percursos")
                tabButton(index: 3, icon: "flag.checkered",  label: "Performance")
                tabButton(index: 4, icon: "chart.bar.fill",  label: "Relatórios")
            }
            .background(.bar)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabButton(index: Int, icon: String, label: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selectedTab == index ? Color.accentColor : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
