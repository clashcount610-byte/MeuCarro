import Charts
import MapKit
import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TripMapView(points: trip.points)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        detailCard("Distância", Format.km(trip.distanceKm), icon: "point.topleft.down.to.point.bottomright.curvepath")
                        detailCard("Tempo", Format.duration(trip.duration), icon: "clock.fill")
                    }
                    HStack(spacing: 12) {
                        detailCard("Vel. média", Format.speed(trip.avgSpeedKmh), icon: "arrow.right")
                        detailCard("Vel. máxima", Format.speed(trip.maxSpeedKmh), icon: "gauge.with.dots.needle.100percent")
                    }
                }

                HStack {
                    Label(Format.dateTimeShort.string(from: trip.startDate), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)

                if trip.points.count > 1 {
                    speedChart
                }
            }
            .padding()
        }
        .navigationTitle(trip.title.isEmpty ? "Percurso" : trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailCard(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var speedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Velocidade ao longo do percurso")
                .font(.headline)
            Chart(Array(trip.points.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("Tempo", index),
                    y: .value("Velocidade (km/h)", point.speed)
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel(format: IntegerFormatStyle<Int>.number)
                }
            }
            .chartYAxisLabel("km/h", position: .trailing)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
    }
}

// MARK: - Mapa do percurso

struct TripMapView: View {
    let points: [TripPoint]

    var body: some View {
        Map {
            if points.count > 1 {
                MapPolyline(coordinates: points.map(\.coordinate))
                    .stroke(.blue, lineWidth: 4)
            }
            if let start = points.first {
                Marker("Início", systemImage: "flag.fill", coordinate: start.coordinate)
                    .tint(.green)
            }
            if let end = points.last, points.count > 1 {
                Marker("Fim", systemImage: "flag.checkered", coordinate: end.coordinate)
                    .tint(.red)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
