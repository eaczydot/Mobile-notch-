import Foundation

#if os(iOS)
import ActivityKit
import UIKit
#endif

public struct CapabilityMatrix: Equatable, Sendable {
    public var supportsLiveActivities: Bool
    public var supportsDynamicIsland: Bool
    public var supportsBatteryModule: Bool
    public var supportsCalendarModule: Bool
    public var supportsShelfModule: Bool

    public init(
        supportsLiveActivities: Bool,
        supportsDynamicIsland: Bool,
        supportsBatteryModule: Bool,
        supportsCalendarModule: Bool,
        supportsShelfModule: Bool
    ) {
        self.supportsLiveActivities = supportsLiveActivities
        self.supportsDynamicIsland = supportsDynamicIsland
        self.supportsBatteryModule = supportsBatteryModule
        self.supportsCalendarModule = supportsCalendarModule
        self.supportsShelfModule = supportsShelfModule
    }

    public static func current() -> CapabilityMatrix {
        #if os(iOS)
        let supportsLiveActivities: Bool
        if #available(iOS 16.1, *) {
            supportsLiveActivities = ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            supportsLiveActivities = false
        }

        let supportsDynamicIsland = supportsDynamicIsland(
            modelIdentifier: currentModelIdentifier(environment: ProcessInfo.processInfo.environment),
            isPhone: UIDevice.current.userInterfaceIdiom == .phone
        )

        return CapabilityMatrix(
            supportsLiveActivities: supportsLiveActivities,
            supportsDynamicIsland: supportsDynamicIsland,
            supportsBatteryModule: true,
            supportsCalendarModule: true,
            supportsShelfModule: true
        )
        #else
        return CapabilityMatrix(
            supportsLiveActivities: false,
            supportsDynamicIsland: false,
            supportsBatteryModule: false,
            supportsCalendarModule: true,
            supportsShelfModule: true
        )
        #endif
    }

    static func supportsDynamicIsland(modelIdentifier: String?, isPhone: Bool) -> Bool {
        guard isPhone, let modelIdentifier else {
            return false
        }

        if ["iPhone15,2", "iPhone15,3"].contains(modelIdentifier) {
            return true
        }

        let parts = modelIdentifier.split(separator: ",", maxSplits: 1)
        guard let family = parts.first,
              family.hasPrefix("iPhone"),
              let major = Int(family.dropFirst("iPhone".count)) else {
            return false
        }

        return major >= 16
    }

    static func currentModelIdentifier(environment: [String: String]) -> String? {
        #if os(iOS)
        if let simulatorIdentifier = environment["SIMULATOR_MODEL_IDENTIFIER"],
           !simulatorIdentifier.isEmpty {
            return simulatorIdentifier
        }

        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        #else
        return nil
        #endif
    }
}
