import SwiftData
import SwiftUI

struct TripsView: View {
    @State private var locationService = LocationService()
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showRecorder = false

    var body: some View {
        Group {
            if trips.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum percurso", systemImage: "mappin.slash")
                } description: {
                    Text("Toque em registrar para gravar sua primeira viagem com GPS.")
                } actions: {
                    Button {
                        showRecorder = true
                    } label: {
                        Label("Registrar percurso", systemImage: "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(trips) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            TripRow(trip: trip)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Percursos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRecorder = true
                } label: {
                    Label("Registrar", systemImage: "record.circle")
                }
            }
        }
        .sheet(isPresented: $showRecorder) {
            AddTripView(locationService: locationService)
        }
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            context.delete(trips[index])
        }
        try? context.save()
    }
}

struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.title.isEmpty ? "Percurso" : trip.title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text("\(Format.dateTimeShort.string(from: trip.startDate)) • \(Format.duration(trip.duration))")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Label(Format.km(trip.distanceKm), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Spacer()
                Label(Format.speed(trip.maxSpeedKmh), systemImage: "gauge.with.dots.needle.67percent")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TripsView()
    }
}
