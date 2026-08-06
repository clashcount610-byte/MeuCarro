import SwiftData
import SwiftUI

struct ZeroToHundredView: View {
    @Environment(\.modelContext) private var context
    @State private var locationService = LocationService()
    @State private var performance: PerformanceService?

    private var service: PerformanceService {
        if let performance { return performance }
        let created = PerformanceService(service: locationService)
        performance = created
        return created
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                speedGauge
                statusText
                resultCard
                instructions
                controls
            }
            .padding()
        }
        .navigationTitle("0–100 km/h")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            service.cancel()
        }
    }

    // MARK: - Velocímetro

    private var speedGauge: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 220, height: 220)
                VStack(spacing: 0) {
                    Text("\(Int(service.currentSpeedKmh))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .monospacedDigit()
                    Text("km/h")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            Gauge(value: min(service.currentSpeedKmh, 220), in: 0...220) { }
                .gaugeStyle(.linearCapacity)
                .tint(gaugeTint)
                .frame(width: 220)
        }
    }

    private var gaugeTint: Color {
        if service.isTiming { return .red }
        if service.isArmed { return .orange }
        return .blue
    }

    // MARK: - Status

    private var statusText: some View {
        Text(statusMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var statusMessage: String {
        if let result = service.result {
            return "Teste concluído em \(Format.stopwatch(result))"
        }
        if service.isTiming {
            return "Cronometrando... aguarde atingir 100 km/h"
        }
        if service.isArmed {
            return "Pronto! Acelere até atingir 100 km/h"
        }
        return "Toque em Armar teste para iniciar"
    }

    // MARK: - Resultado

    @ViewBuilder
    private var resultCard: some View {
        if let result = service.result {
            VStack(spacing: 12) {
                Label("Resultado", systemImage: "flag.checkered")
                    .font(.headline)
                Text(Format.stopwatch(result))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Velocidade máxima: \(Format.speed(service.currentSpeedKmh))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    saveResult(result)
                } label: {
                    Label("Salvar resultado", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private func saveResult(_ result: TimeInterval) {
        let run = PerformanceRun(
            typeRaw: PerformanceType.zeroToHundred.rawValue,
            duration: result,
            maxSpeedKmh: service.currentSpeedKmh
        )
        context.insert(run)
        try? context.save()
        service.cancel()
    }

    // MARK: - Instruções e controles

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Como funciona", systemImage: "info.circle.fill")
                .font(.headline)
            Text("1. Pare o veículo em um local seguro e plano.")
            Text("2. Toque em \"Armar teste\": o cronômetro dispara automaticamente ao começar a acelerar.")
            Text("3. O tempo é registrado quando a velocidade atinge 100 km/h (medição por GPS, aproximada).")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if service.isArmed || service.isTiming {
                Button(role: .destructive) {
                    service.cancel()
                } label: {
                    Label("Cancelar", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    service.arm()
                } label: {
                    Label("Armar teste", systemImage: "flag.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ZeroToHundredView()
    }
}
