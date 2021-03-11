//
//  DismissCardAnimator.swift
//  Kickster
//
//  Created by Razvan Chelemen on 06/05/2019.
//  Copyright © 2019 appssemble. All rights reserved.
//

import UIKit

final class DismissCardAnimator: CardAnimator {
    
    struct Constants {
        static let relativeDurationBeforeNonInteractive: TimeInterval = 0.5
        static let minimumScaleBeforeNonInteractive: CGFloat = 0.8
    }
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return params.settings.dismissalAnimationDuration
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let ctx = transitionContext
        let container = ctx.containerView
                
        guard let fromViewController = ctx.viewController(forKey: .from),
              let cardDetailViewController = cardDetailForController(fromViewController) else { return }
        
        let toViewController = ctx.viewController(forKey: .to)
        
        let fromView = ctx.view(forKey: .from)!
        
        let animatedContainerView = UIView()
        if params.settings.isEnabledDebugAnimatingViews {
            animatedContainerView.layer.borderColor = UIColor.yellow.cgColor
            animatedContainerView.layer.borderWidth = 4
            fromView.layer.borderColor = UIColor.red.cgColor
            fromView.layer.borderWidth = 2
        }
        animatedContainerView.translatesAutoresizingMaskIntoConstraints = false
        fromView.translatesAutoresizingMaskIntoConstraints = false
        
        container.removeConstraints(container.constraints)
        
        animatedContainerView.addSubview(fromView)
        fromView.edges(to: animatedContainerView)
        
        let safeAreaClippingView = UIView(frame: container.bounds)
//        safeAreaClippingView.backgroundColor = .yellow
        
        let safeAreaMaskView = UIView()
        safeAreaMaskView.backgroundColor = .black
        safeAreaMaskView.frame = safeAreaClippingView.bounds
        safeAreaClippingView.mask = safeAreaMaskView
        
        safeAreaClippingView.addSubview(animatedContainerView)
        container.addSubview(safeAreaClippingView)
        
        let animatedContainerCenterXConstraint = animatedContainerView.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        let animatedContainerTopConstraint = animatedContainerView.topAnchor.constraint(equalTo: container.topAnchor, constant: params.settings.cardContainerInsets.top)
        let animatedContainerWidthConstraint = animatedContainerView.widthAnchor.constraint(equalToConstant: fromView.frame.width - (params.settings.cardContainerInsets.left + params.settings.cardContainerInsets.right))
        let animatedContainerHeightConstraint = animatedContainerView.heightAnchor.constraint(equalToConstant: fromView.frame.height - (params.settings.cardContainerInsets.top + params.settings.cardContainerInsets.bottom))
        
        NSLayoutConstraint.activate([animatedContainerCenterXConstraint,
                                     animatedContainerTopConstraint,
                                     animatedContainerWidthConstraint,
                                     animatedContainerHeightConstraint])
        
        // Fix weird top inset
        let topTemporaryFix = cardDetailViewController.cardContentView.topAnchor.constraint(equalTo: fromView.topAnchor)
        topTemporaryFix.isActive = params.settings.isEnabledWeirdTopInsetsFix
        
        container.layoutIfNeeded()
        
        // Force card filling bottom
        let stretchCardToFillBottom = cardDetailViewController.cardContentView.bottomAnchor.constraint(equalTo: fromView.bottomAnchor)
        // for tableview header required confilcts with autoresizing mask constraints
        stretchCardToFillBottom.priority = .defaultHigh
        
        func animateCardViewBackToPlace() {
            stretchCardToFillBottom.isActive = true
            //screens.cardDetail.isFontStateHighlighted = false
            // Back to identity
            // NOTE: Animated container view in a way, helps us to not messing up `transform` with `AutoLayout` animation.
            fromView.transform = CGAffineTransform.identity
            
            fromView.layer.cornerRadius = params.settings.cardCornerRadius
            
            animatedContainerCenterXConstraint.constant = self.params.fromCardFrameWithoutTransform.midX + params.settings.cardContainerInsets.left - container.bounds.width/2
            animatedContainerTopConstraint.constant = self.params.fromCardFrameWithoutTransform.minY + params.settings.cardContainerInsets.top
            animatedContainerWidthConstraint.constant = self.params.fromCardFrameWithoutTransform.width - (params.settings.cardContainerInsets.left + params.settings.cardContainerInsets.right)
            animatedContainerHeightConstraint.constant = self.params.fromCardFrameWithoutTransform.height - (params.settings.cardContainerInsets.top + params.settings.cardContainerInsets.bottom)
            
            params.settings.additionalCardViewAnimations?(cardDetailViewController.cardContentView, false)
            
            container.layoutIfNeeded()
            
            if let toViewController = toViewController?.topViewController() {
                safeAreaMaskView.frame = container.bounds.inset(by: toViewController.view.safeAreaInsets)
            }
            
        }
        
        func completeEverything() {
            let success = !ctx.transitionWasCancelled
            animatedContainerView.removeConstraints(animatedContainerView.constraints)
            animatedContainerView.removeFromSuperview()
            if success {
                fromView.removeFromSuperview()
                self.params.fromCell.isHidden = false
            } else {
                //screens.cardDetail.isFontStateHighlighted = true
                
                // Remove temporary fixes if not success!
                topTemporaryFix.isActive = false
                stretchCardToFillBottom.isActive = false
                
                fromView.removeConstraint(topTemporaryFix)
                fromView.removeConstraint(stretchCardToFillBottom)
                
                container.removeConstraints(container.constraints)
                
                container.addSubview(fromView)
                fromView.edges(to: container)
            }
            ctx.completeTransition(success)
        }
        
        cardDetailViewController.didBeginDismissAnimation()
        
        UIView.animate(withDuration: transitionDuration(using: ctx), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [], animations: {
            animateCardViewBackToPlace()
        }) { (finished) in
            completeEverything()
        }
        
        UIView.animate(withDuration: transitionDuration(using: ctx) * 0.4) {
            //print("godam")
            //screens.cardDetail.scrollView.setContentOffset(self.params.settings.dismissalScrollViewContentOffset, animated: true)
            cardDetailViewController.scrollView?.contentOffset = self.params.settings.dismissalScrollViewContentOffset
        }
    }
}
