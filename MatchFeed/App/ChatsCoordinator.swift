//
//  ChatCoordinator.swift
//  MatchFeed
//
//  Created by Sadat on 4/22/26.
//

import UIKit

final class ChatsCoordinator {
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Chats"
        navigationController.setViewControllers([vc], animated: false)
    }
}
