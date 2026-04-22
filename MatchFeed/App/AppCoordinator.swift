import UIKit
import SwiftUI

// MARK: - AppCoordinator
// Owns navigation — ViewModels never import UIKit or know about routing.

final class AppCoordinator {

    let navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        navigationController.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Entry point

    func start() {
        showFeed()
    }

    // MARK: - Navigation

    func showFeed() {
        let vm = FeedViewModel()
        let vc = FeedViewController(viewModel: vm)
        vc.coordinator = self
        // Pass the coordinator down so the VC can call showChat(with:)
        // In a real coordinator pattern you'd use a delegate or closure:
        // vc.onProfileTapped = { [weak self] profile in self?.showChat(with: profile) }
        navigationController.setViewControllers([vc], animated: false)
    }

    func showChat(with profile: UserProfile) {
        let chatView  = ChatView(partner: profile)
        let hostingVC = UIHostingController(rootView: chatView)
        hostingVC.title = profile.firstName
        navigationController.pushViewController(hostingVC, animated: true)
    }
}
