import SwiftData
import SwiftUI

struct PerformanceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PerformanceRun.date, order: .reverse) private var runs: [PerformanceRun]

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ZeroToHundredView()
                } label: {
                    labelCard("0–100 km/h", "Medição por GPS", "gauge.with.dots.needle.67percent")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                NavigationLink {
                    ColdStartView()
                } label: {
                    labelCard("Cold Start", "Cronômetro de partida", "timer")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Histórico") {
                if runs.isEmpty {
                    Text("Nenhum teste salvo ainda.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(runs) { run in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(run.type.label).fontWeight(.semibold)
                                Text(Format.dateTimeShort.string(from: run.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Format.stopwatch(run.duration))
                                .fontWeight(.bold)
                        }
                        .contextMenu {
                            Button("Excluir", role: .destructive) {
                                context.delete(run)
                                try? context.save()
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Performance")
    }

    private func labelCard(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.primary)
    }
}
