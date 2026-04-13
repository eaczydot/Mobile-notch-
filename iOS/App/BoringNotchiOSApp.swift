import SwiftUI

@main
struct BoringNotchiOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var runtimeStore = IslandRuntimeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(runtimeStore)
                .task {
                    await runtimeStore.bootstrap()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await runtimeStore.sceneDidBecomeActive()
                    }
                }
        }
    }
}
