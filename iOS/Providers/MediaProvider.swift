import Foundation

final class MediaProvider: IslandEventProvider {
    private let streamStorage: AsyncStream<IslandEvent>
    private let continuation: AsyncStream<IslandEvent>.Continuation
    private var timer: Timer?
    private var progress: Double = 0

    init() {
        var continuation: AsyncStream<IslandEvent>.Continuation?
        let stream = AsyncStream<IslandEvent> { cont in
            continuation = cont
        }
        self.streamStorage = stream
        self.continuation = continuation!
    }

    var eventStream: AsyncStream<IslandEvent> {
        streamStorage
    }

    func start() async {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.progress = min(1, self.progress + 0.05)
            continuation.yield(
                IslandEvent(
                    module: .media,
                    payload: .media(.init(
                        title: "Provider Track",
                        subtitle: "Provider Artist",
                        progress: self.progress,
                        isPlaying: true
                    ))
                )
            )
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
