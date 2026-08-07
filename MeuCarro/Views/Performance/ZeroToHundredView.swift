import SwiftData
import SwiftUI

struct ZeroToHundredView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var locationService: LocationService
    @StateObject private var performance: PerformanceService

    init() {
        let location = LocationService()
        _locationService = StateObject(wrappedValue: location)
        _performance = StateObject(wrappedValue: PerformanceService(service: location))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(String(format: "%.0f", performance.currentSpeedKmh))
                .font(.system(size: 72, weight: .bold, design: .rounded))
            Text("km/h").foregroundStyle(.secondary)

            Text(statusText)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let result = performance.result {
                VStack(spacing: 12) {
                    Text("Resultado").font(.headline)
                    Text(Format.stopwatch(result))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Button("Salvar resultado") {
                        let run = PerformanceRun(
                            typeRaw: PerformanceType.zeroToHundred.rawValue,
                            duration: result,
                            maxSpeedKmh: performance.currentSpeedKmh
                        )
                        context.insert(run)
                        try? context.save()
                        performance.cancel()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if performance.isArmed || performance.isTiming {
                Button("Cancelar", role: .destructive, action: performance.cancel)
                    .buttonStyle(.bordered)
            } else if performance.result == nil {
                Button("Armar teste", action: performance.arm)
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("0–100 km/h")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { performance.cancel() }
    }

    private var statusText: String {
        if performance.result != nil { return "Teste concluído" }
        if performance.isTiming { return "Cronometrando… acelere até 100 km/h" }
        if performance.isArmed { return "Pronto. Acelere para iniciar" }
        return "Pare o veículo e toque em Armar teste"
    }
}
