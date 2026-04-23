//
//  RootCoordinator.swift
//  MatchFeed
//
//  Created by Sadat on 4/22/26.
//

import UIKit

final class RootCoordinator {
    
    let tabBarController = UITabBarController()
    
    // Each tab gets its own nav stack
    private let discoverNav = UINavigationController()
    private let chatsNav    = UINavigationController()
    
    // Child coordinators
    private lazy var discoverCoordinator = DiscoverCoordinator(navigationController: discoverNav)
    private lazy var chatsCoordinator    = ChatsCoordinator(navigationController: chatsNav)
    
    func start() {
        discoverNav.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "flame"), tag: 0)
        chatsNav.tabBarItem    = UITabBarItem(title: "Chats",    image: UIImage(systemName: "message"), tag: 1)
        
        tabBarController.viewControllers = [discoverNav, chatsNav]
        tabBarController.tabBar.tintColor = .systemPink
        
        discoverCoordinator.start()
        chatsCoordinator.start()
    }
}
