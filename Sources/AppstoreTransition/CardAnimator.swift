//
//  CardAnimator.swift
//  appstore-card-transition
//
//  Created by Max Lesichniy on 26.11.2020.
//

import UIKit

class CardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    struct Params {
        let fromCardFrame: CGRect
        let fromCardFrameWithoutTransform: CGRect
        let fromCell: CardCollectionViewCell
        let settings: CardTransitionSettings
    }
    
    let params: Params

    init(params: Params) {
        self.params = params
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
    
    func cardsForController(_ controller: UIViewController) -> CardsViewController? {
        if let comform = controller as? CardsViewController {
            return comform
        }
        for itemController in controller.children {
            if let c = cardsForController(itemController) {
                return c
            }
        }
        return nil
    }
    
    func cardDetailForController(_ controller: UIViewController) -> CardDetailViewController? {
        if let comform = controller as? CardDetailViewController {
            return comform
        }
        for itemController in controller.children {
            if let c = cardDetailForController(itemController) {
                return c
            }
        }
        return nil
    }
    
}
