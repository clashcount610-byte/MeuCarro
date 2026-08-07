import SwiftData
import SwiftUI

// MARK: - Container (somente @Query)
struct PerformanceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PerformanceRun.date, order: .reverse) private var runs: [PerformanceRun]

    var body: some View {
        PerformanceContent(runs: runs, onDelete: { run in
            context.delete(run)
            try? context.save()
        })
        .navigationTitle("Performance")
    }
}

// MARK: - View de conteúdo (sem @Query)
private struct PerformanceContent: View {
    let runs: [PerformanceRun]
    let onDelete: (PerformanceRun) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink {
                    ZeroToHundredView()
                } label: {
                    labelCard("0–100 km/h", "Medição por GPS", "gauge.with.dots.needle.67percent")
                }

                NavigationLink {
                    ColdStartView()
                } label: {
                    labelCard("Cold Start", "Cronômetro de partida", "timer")
                }

                Text("Histórico").font(.headline).padding(.top, 8)

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
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .contextMenu {
                            Button("Excluir", role: .destructive) { onDelete(run) }
                        }
                    }
                }
            }
            .padding()
        }
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
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.primary)
    }
}
