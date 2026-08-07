import SwiftData
import SwiftUI

// MARK: - Container (somente @Query)
struct FuelView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @State private var showAdd = false
    @State private var tab = 0

    var body: some View {
        FuelContent(
            fills: fills,
            tab: $tab,
            showAdd: $showAdd,
            onDelete: { fill in
                context.delete(fill)
                try? context.save()
            }
        )
        .navigationTitle("Combustível")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { AddFuelView() }
        }
    }
}

// MARK: - View de conteúdo (sem @Query)
private struct FuelContent: View {
    let fills: [FuelFill]
    @Binding var tab: Int
    @Binding var showAdd: Bool
    let onDelete: (FuelFill) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("Histórico").tag(0)
                Text("Comparar").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if tab == 0 {
                history
            } else {
                FuelComparatorView()
            }
        }
    }

    private var history: some View {
        Group {
            if fills.isEmpty {
                ContentUnavailableView(
                    "Sem abastecimentos",
                    systemImage: "fuelpump",
                    description: Text("Toque em + para registrar o primeiro.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(fills) { fill in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(Format.dateMedium.string(from: fill.date))
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(Format.money(fill.totalCost))
                                }
                                Text("\(Format.liters(fill.liters)) · \(Format.pricePerLiter(fill.pricePerLiter)) · \(Format.km(fill.odometerKm))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if fill.isFullTank {
                                    Text("Tanque cheio")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.green.opacity(0.2), in: Capsule())
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                            .contextMenu {
                                Button("Excluir", role: .destructive) { onDelete(fill) }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
