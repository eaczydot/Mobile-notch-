import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let actionController = IslandActionController()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task { @MainActor in
            await persistIncomingItemsAndComplete()
        }
    }

    private func persistIncomingItemsAndComplete() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        var collectedItems: [ShelfItemRecord] = []

        for item in items {
            for provider in item.attachments ?? [] {
                if let record = await loadRecord(from: provider) {
                    collectedItems.append(record)
                }
            }
        }

        if !collectedItems.isEmpty {
            try? await actionController.append(collectedItems)
        }

        completeRequest()
    }

    private func loadRecord(from provider: NSItemProvider) async -> ShelfItemRecord? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = await loadURL(from: provider) {
            return .from(url: url)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = await loadText(from: provider),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .from(text: text)
        }

        return nil
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                if let text = item as? String, let url = URL(string: text) {
                    continuation.resume(returning: url)
                    return
                }

                if let text = item as? NSString, let url = URL(string: text as String) {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                    return
                }

                if let text = item as? NSString {
                    continuation.resume(returning: text as String)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
