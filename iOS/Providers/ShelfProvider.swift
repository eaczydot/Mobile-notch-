import Foundation

final class ShelfProvider: IslandEventProvider {
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
            IslandEvent(module: .shelf, payload: .shelf(.init(itemCount: 2, lastItemName: "Proposal.pdf")))
        )
    }

    func stop() {}
}
