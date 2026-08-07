import MapKit
import SwiftData
import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @StateObject private var recorder: TripRecorder
    @State private var showDiscardConfirm = false

    init(locationService: LocationService) {
        _recorder = StateObject(wrappedValue: TripRecorder(service: locationService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TripRecorderMapView(recorder: recorder)
                    .frame(maxHeight: .infinity)

                VStack(spacing: 14) {
                    HStack {
                        metric("Distância", Format.km(recorder.distanceKm))
                        metric("Tempo", Format.duration(recorder.elapsed))
                        metric("Média", Format.speed(recorder.avgSpeedKmh))
                        metric("Máx", Format.speed(recorder.maxSpeedKmh))
                    }

                    if recorder.isRecording {
                        HStack {
                            Button("Descartar", role: .destructive) { showDiscardConfirm = true }
                                .buttonStyle(.bordered)
                            Button("Salvar e parar") { save() }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Button("Iniciar gravação") { recorder.start() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Registrar percurso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        if recorder.isRecording { _ = recorder.stop() }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Descartar percurso?", isPresented: $showDiscardConfirm) {
                Button("Descartar", role: .destructive) {
                    _ = recorder.stop()
                    dismiss()
                }
            }
            .onAppear { recorder.start() }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard let trip = recorder.stop() else {
            dismiss()
            return
        }
        context.insert(trip)
        if let vehicle = vehicles.first {
            vehicle.odometerKm += trip.distanceKm
        }
        try? context.save()
        dismiss()
    }
}

struct TripRecorderMapView: View {
    @ObservedObject var recorder: TripRecorder
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera) {
            if recorder.points.count > 1 {
                MapPolyline(coordinates: recorder.points.map(\.coordinate))
                    .stroke(.blue, lineWidth: 4)
            }
            if let last = recorder.latestPoint {
                Marker("Atual", coordinate: last.coordinate)
            }
        }
        .onChange(of: recorder.points.count) { _ in
            if let last = recorder.latestPoint {
                camera = .camera(MapCamera(centerCoordinate: last.coordinate, distance: 1500))
            }
        }
    }
}
