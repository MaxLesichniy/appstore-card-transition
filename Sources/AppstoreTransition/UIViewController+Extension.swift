//
//  UIViewController+Extension.swift
//  AppstoreTransition
//
//  Created by Razvan Chelemen on 15/05/2019.
//  Copyright © 2019 appssemble. All rights reserved.
//

import Foundation

public extension UIViewController {
    
    func presentExpansion(_ viewControllerToPresent: UIViewController, cell: CardCollectionViewCell, animated flag: Bool, completion: (() -> Void)? = nil) {
        present(viewControllerToPresent, animated: flag, completion: { [unowned cell] in
            // Unfreeze
            cell.unfreezeAnimations()
            completion?()
        })
    }
    
    func topViewController() -> UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topViewController()
        }
        if let tabController = self as? UITabBarController {
            return tabController.selectedViewController?.topViewController()
        }
        for child in children {
            if let topViewController = child.topViewController() {
                return topViewController
            }
        }
        return self
    }
    
}
