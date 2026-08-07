import SwiftData
import SwiftUI

struct ColdStartView: View {
    @Environment(\.modelContext) private var context
    @State private var startDate: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                Text(displayTime(at: timeline.date))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            Text("Cronômetro de partida").foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("Reiniciar") { reset() }
                    .buttonStyle(.bordered)
                    .disabled(accumulated == 0 && !isRunning)

                Button(isRunning ? "Parar" : "Iniciar") {
                    isRunning ? pause() : start()
                }
                .buttonStyle(.borderedProminent)

                Button("Salvar") { save() }
                    .buttonStyle(.bordered)
                    .disabled(accumulated <= 0 || isRunning)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Cold Start")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayTime(at now: Date) -> String {
        let elapsed = accumulated + (isRunning ? now.timeIntervalSince(startDate ?? now) : 0)
        return Format.stopwatch(elapsed)
    }

    private func start() {
        startDate = .now
        isRunning = true
    }

    private func pause() {
        if let startDate {
            accumulated += Date.now.timeIntervalSince(startDate)
        }
        isRunning = false
    }

    private func reset() {
        accumulated = 0
        isRunning = false
        startDate = nil
    }

    private func save() {
        guard accumulated > 0 else { return }
        context.insert(PerformanceRun(typeRaw: PerformanceType.coldStart.rawValue, duration: accumulated))
        try? context.save()
        reset()
    }
}
