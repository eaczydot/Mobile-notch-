import Foundation

final class CalendarProvider: IslandEventProvider {
    private let streamStorage: AsyncStream<IslandEvent>
    private let continuation: AsyncStream<IslandEvent>.Continuation

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
        continuation.yield(
            IslandEvent(
                module: .calendar,
                payload: .calendar(.init(title: "Design Sync", startsAt: Date().addingTimeInterval(1800)))
            )
        )
    }

    func stop() {}
}
