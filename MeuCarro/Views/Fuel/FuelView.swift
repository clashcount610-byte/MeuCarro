import SwiftData
import SwiftUI

struct FuelView: View {
    @Query(sort: \FuelFill.date, order: .reverse) private var fills: [FuelFill]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Seção", selection: $selectedSegment) {
                Text("Histórico").tag(0)
                Text("Comparar").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if selectedSegment == 0 {
                historyList
            } else {
                FuelComparatorView()
            }
        }
        .navigationTitle("Combustível")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { AddFuelView() }
        }
    }

    // MARK: - Histórico

    private struct MonthSection: Identifiable {
        let id: Date
        let title: String
        let fills: [FuelFill]
    }

    private var monthSections: [MonthSection] {
        let grouped = Dictionary(grouping: fills) { $0.date.startOfMonth }
        return grouped.keys.sorted(by: >).map { month in
            MonthSection(
                id: month,
                title: month.formatted(.dateTime.month(.wide).year()),
                fills: grouped[month]!.sorted { $0.date > $1.date }
            )
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if fills.isEmpty {
            ContentUnavailableView {
                Label("Sem abastecimentos", systemImage: "fuelpump.slash")
            } description: {
                Text("Registre o primeiro abastecimento para acompanhar o consumo real.")
            } actions: {
                Button("Registrar abastecimento") {
                    showAdd = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(monthSections) { section in
                    Section(section.title) {
                        ForEach(section.fills) { fill in
                            FuelRow(fill: fill)
                        }
                        .onDelete { indexSet in
                            deleteFills(indexSet, in: section)
                        }
                    }
                }
            }
        }
    }

    private func deleteFills(_ indexSet: IndexSet, in section: MonthSection) {
        for index in indexSet {
            let fill = section.fills[index]
            context.delete(fill)
        }
        try? context.save()
    }
}

struct FuelRow: View {
    let fill: FuelFill

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(fill.fuelType.label, systemImage: fill.fuelType.icon)
                    .font(.subheadline)
                    .foregroundStyle(fill.fuelType.color)
                Spacer()
                if fill.isFullTank {
                    Text("Tanque cheio")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                        .foregroundStyle(.green)
                }
            }

            Text(Format.dateTimeShort.string(from: fill.date))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(Format.liters(fill.liters))
                Text("•")
                    .foregroundStyle(.secondary)
                Text(Format.pricePerLiter(fill.pricePerLiter))
                Spacer()
                Text(Format.money(fill.totalCost))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            Text("Odômetro: \(Format.km(fill.odometerKm))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
