import Foundation

public enum IslandModuleID: String, Codable, CaseIterable, Sendable {
    case media
    case battery
    case calendar
    case shelf
    case event
}

public enum IslandModuleCompactStyle: String, Codable, CaseIterable, Sendable {
    case iconOnly
    case iconAndText
    case progress
}

public enum IslandModuleExpandedStyle: String, Codable, CaseIterable, Sendable {
    case rich
    case minimal
    case timeline
}

public enum IslandActionID: String, Codable, CaseIterable, Sendable {
    case playPause
    case nextTrack
    case previousTrack
    case mute
    case dismiss
    case openApp
}
