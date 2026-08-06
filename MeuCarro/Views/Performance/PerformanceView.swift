import SwiftData
import SwiftUI

struct PerformanceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PerformanceRun.date, order: .reverse) private var runs: [PerformanceRun]

    var body: some View {
        List {
            Section("Testes") {
                NavigationLink {
                    ZeroToHundredView()
                } label: {
                    Label("0–100 km/h", systemImage: "gauge.with.dots.needle.67percent")
                }
                NavigationLink {
                    ColdStartView()
                } label: {
                    Label("Cold Start (cronômetro)", systemImage: "bolt.fill")
                }
            }

            Section("Histórico de testes") {
                if runs.isEmpty {
                    Text("Nenhum teste registrado ainda.")
                        .foregroundStyle(.secondary)
                }
                ForEach(runs) { run in
                    HStack(spacing: 12) {
                        Image(systemName: run.type.icon)
                            .foregroundStyle(run.type.color)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(run.type.label)
                                .fontWeight(.medium)
                            Text(Format.dateTimeShort.string(from: run.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Format.stopwatch(run.duration))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Performance")
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            context.delete(runs[index])
        }
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        PerformanceView()
    }
}
