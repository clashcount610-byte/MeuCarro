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
                VStack(spacing: 8) {
                    Text(displayTime(at: timeline.date))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("Cronômetro de partida")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            controls

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

    // MARK: - Controles

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                reset()
            } label: {
                Label("Reiniciar", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(accumulated == 0 && !isRunning)

            Button {
                isRunning ? pause() : start()
            } label: {
                Label(isRunning ? "Parar" : "Iniciar", systemImage: isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRunning ? .red : .green)

            Button {
                save()
            } label: {
                Label("Salvar", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(accumulated <= 0 || isRunning)
        }
    }

    // MARK: - Ações

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
        let run = PerformanceRun(
            typeRaw: PerformanceType.coldStart.rawValue,
            duration: accumulated
        )
        context.insert(run)
        try? context.save()
        reset()
    }
}

#Preview {
    NavigationStack {
        ColdStartView()
    }
}
