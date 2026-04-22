import SwiftUI

// MARK: - App Entry Point

@main
struct MatchFeedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // Hand control to UIKit coordinator for the main flow
            CoordinatorView(coordinator: appDelegate.coordinator)
                .ignoresSafeArea()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    var coordinator: AppCoordinator!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        coordinator = AppCoordinator()
        coordinator.start()
        return true
    }
}

// MARK: - UIKit ↔ SwiftUI bridge

/// Wraps the coordinator's UINavigationController so SwiftUI's WindowGroup can host it.
struct CoordinatorView: UIViewControllerRepresentable {
    let coordinator: AppCoordinator

    func makeUIViewController(context: Context) -> UINavigationController {
        coordinator.navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
