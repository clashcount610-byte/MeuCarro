import Charts
import MapKit
import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TripMapView(points: trip.points)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    row("Distância", Format.km(trip.distanceKm))
                    row("Duração", Format.duration(trip.duration))
                    row("Vel. média", Format.speed(trip.avgSpeedKmh))
                    row("Vel. máxima", Format.speed(trip.maxSpeedKmh))
                    row("Início", Format.dateTimeShort.string(from: trip.startDate))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                if trip.points.count > 1 {
                    Chart {
                        ForEach(Array(trip.points.enumerated()), id: \.offset) { index, point in
                            LineMark(
                                x: .value("t", index),
                                y: .value("km/h", point.speed)
                            )
                        }
                    }
                    .frame(height: 160)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle(trip.title.isEmpty ? "Percurso" : trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}

struct TripMapView: View {
    let points: [TripPoint]

    var body: some View {
        Map {
            if points.count > 1 {
                MapPolyline(coordinates: points.map(\.coordinate))
                    .stroke(.blue, lineWidth: 4)
            }
            if let first = points.first {
                Marker("Início", coordinate: first.coordinate)
            }
            if let last = points.last, points.count > 1 {
                Marker("Fim", coordinate: last.coordinate)
            }
        }
    }
}
