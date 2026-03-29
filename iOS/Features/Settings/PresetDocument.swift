import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let boringNotchPreset = UTType(exportedAs: "name.theboringteam.boringnotch.preset")
}

struct PresetDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.boringNotchPreset, .json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
