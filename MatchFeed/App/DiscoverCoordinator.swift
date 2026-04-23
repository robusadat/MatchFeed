import UIKit
import SwiftUI

// MARK: - DiscoverCoordinator
// Owns navigation — ViewModels never import UIKit or know about routing.

final class DiscoverCoordinator {

    let navigationController: UINavigationController
    weak var feedViewModel: FeedViewModel?

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
        feedViewModel = vm
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
    
    func showProfile(for profile: UserProfile) {
        let view = ProfileView(
            profile: profile,
            onLike: { [weak self] in
                Task { await self?.feedViewModel?.swipe(profile: profile, direction: .like) }
                self?.navigationController.popViewController(animated: true)
            },
            onPass: { [weak self] in
                Task { await self?.feedViewModel?.swipe(profile: profile, direction: .pass) }
                self?.navigationController.popViewController(animated: true)
            }
        )
        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }
}
