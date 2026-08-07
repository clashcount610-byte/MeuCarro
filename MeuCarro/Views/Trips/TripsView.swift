import SwiftData
import SwiftUI

// MARK: - Container (somente @Query)
struct TripsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @StateObject private var locationService = LocationService()
    @State private var showRecorder = false

    var body: some View {
        TripsContent(
            trips: trips,
            showRecorder: $showRecorder,
            onDelete: { trip in
                context.delete(trip)
                try? context.save()
            }
        )
        .navigationTitle("Percursos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Registrar") { showRecorder = true }
            }
        }
        .sheet(isPresented: $showRecorder) {
            AddTripView(locationService: locationService)
        }
    }
}

// MARK: - View de conteúdo (sem @Query)
private struct TripsContent: View {
    let trips: [Trip]
    @Binding var showRecorder: Bool
    let onDelete: (Trip) -> Void

    var body: some View {
        Group {
            if trips.isEmpty {
                ContentUnavailableView(
                    "Nenhum percurso",
                    systemImage: "map",
                    description: Text("Toque em Registrar para gravar uma viagem com GPS.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(trip.title.isEmpty ? "Percurso" : trip.title)
                                        .fontWeight(.semibold)
                                    Text("\(Format.dateTimeShort.string(from: trip.startDate)) · \(Format.duration(trip.duration))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text(Format.km(trip.distanceKm))
                                        Spacer()
                                        Text("máx \(Format.speed(trip.maxSpeedKmh))")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Excluir", role: .destructive) { onDelete(trip) }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
