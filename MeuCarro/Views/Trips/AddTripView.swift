import MapKit
import SwiftData
import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var vehicles: [VehicleInfo]
    @State private var recorder: TripRecorder
    @State private var showDiscardConfirm = false

    init(locationService: LocationService) {
        _recorder = State(initialValue: TripRecorder(service: locationService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TripRecorderMapView(recorder: recorder)
                    .frame(maxHeight: .infinity)

                VStack(spacing: 14) {
                    statsRow
                    controls
                }
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("Registrar percurso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        if recorder.isRecording {
                            _ = recorder.stop()
                        }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Descartar este percurso?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
                Button("Descartar", role: .destructive) {
                    _ = recorder.stop()
                    dismiss()
                }
            }
            .onAppear {
                recorder.start()
            }
        }
    }

    // MARK: - Estatísticas ao vivo

    private var statsRow: some View {
        HStack(spacing: 8) {
            liveStat(title: "Distância", value: Format.km(recorder.distanceKm))
            liveStat(title: "Tempo", value: elapsedText)
            liveStat(title: "Vel. média", value: Format.speed(recorder.avgSpeedKmh))
            liveStat(title: "Vel. máx", value: Format.speed(recorder.maxSpeedKmh))
        }
    }

    private var elapsedText: String {
        Format.duration(recorder.elapsed)
    }

    private func liveStat(title: String, value: String) -> some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Controles

    @ViewBuilder
    private var controls: some View {
        if recorder.isRecording {
            HStack(spacing: 12) {
                Button {
                    showDiscardConfirm = true
                } label: {
                    Label("Descartar", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    save()
                } label: {
                    Label("Salvar e parar", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        } else {
            Button {
                recorder.start()
            } label: {
                Label("Retomar gravação", systemImage: "record.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
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

// MARK: - Mapa ao vivo

struct TripRecorderMapView: View {
    let recorder: TripRecorder
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera) {
            if recorder.points.count > 1 {
                MapPolyline(coordinates: recorder.points.map(\.coordinate))
                    .stroke(.blue, lineWidth: 4)
            }
            if let first = recorder.points.first {
                Marker("Início", systemImage: "flag.fill", coordinate: first.coordinate)
                    .tint(.green)
            }
            if let last = recorder.latestPoint {
                Marker("Atual", systemImage: "location.fill", coordinate: last.coordinate)
                    .tint(.red)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: recorder.points.count) {
            guard let last = recorder.latestPoint else { return }
            withAnimation {
                camera = .camera(MapCamera(centerCoordinate: last.coordinate, distance: 1500))
            }
        }
        .onAppear {
            if let location = recorder.currentLocation {
                camera = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 1000))
            }
        }
    }
}
