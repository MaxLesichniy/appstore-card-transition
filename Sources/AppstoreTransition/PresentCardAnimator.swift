//
//  PresentCardAnimator.swift
//  Kickster
//
//  Created by Razvan Chelemen on 06/05/2019.
//  Copyright © 2019 appssemble. All rights reserved.
//

import UIKit

final class PresentCardAnimator: CardAnimator {
    
    private let presentAnimationDuration: TimeInterval
    private let springAnimator: UIViewPropertyAnimator
    private var transitionDriver: PresentCardTransitionDriver?
    
    override init(params: Params) {
        self.springAnimator = PresentCardAnimator.createBaseSpringAnimator(params: params)
        self.presentAnimationDuration = springAnimator.duration
        super.init(params: params)
    }
    
    private static func createBaseSpringAnimator(params: PresentCardAnimator.Params) -> UIViewPropertyAnimator {
        // Damping between 0.7 (far away) and 1.0 (nearer)
        let cardPositionY = params.fromCardFrame.minY
        let distanceToBounce = abs(params.fromCardFrame.minY)
        let extentToBounce = cardPositionY < 0 ? params.fromCardFrame.height : UIScreen.main.bounds.height
        let dampFactorInterval: CGFloat = 0.3
        let damping: CGFloat = 1.0 - dampFactorInterval * (distanceToBounce / extentToBounce)
        
        // Duration between 0.5 (nearer) and 0.9 (nearer)
        let baselineDuration: TimeInterval = 0.5
        let maxDuration: TimeInterval = 0.9
        let duration: TimeInterval = baselineDuration + (maxDuration - baselineDuration) * TimeInterval(max(0, distanceToBounce)/UIScreen.main.bounds.height)
        
        let springTiming = UISpringTimingParameters(dampingRatio: damping, initialVelocity: .init(dx: 0, dy: 0))
        return UIViewPropertyAnimator(duration: duration, timingParameters: springTiming)
    }
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presentAnimationDuration
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let cardDetailViewController = cardDetailForController(toViewController) else { return }
        
        transitionDriver = PresentCardTransitionDriver(params: params,
                                                       transitionContext: transitionContext,
                                                       cardDetailViewController: cardDetailViewController,
                                                       baseAnimator: springAnimator)
        transitionDriver!.animator.startAnimation()
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        return transitionDriver!.animator
    }
    
}

final class PresentCardTransitionDriver {
    
    let animator: UIViewPropertyAnimator
    
    init(params: PresentCardAnimator.Params,
         transitionContext: UIViewControllerContextTransitioning,
         cardDetailViewController: CardDetailViewController,
         baseAnimator: UIViewPropertyAnimator) {
        
        let ctx = transitionContext
        let containerView = ctx.containerView
        
        let toViewController = ctx.viewController(forKey: .to)
        let finalFrame = toViewController.map { ctx.finalFrame(for: $0) } ?? containerView.bounds
        
        let toView = ctx.view(forKey: .to)!
        toView.backgroundColor = .clear
        let fromCardFrame = params.fromCardFrame
        
        // Temporary container view for animation
        let animatedContainerView = UIView()
        animatedContainerView.translatesAutoresizingMaskIntoConstraints = false
        if params.settings.isEnabledDebugAnimatingViews {
            animatedContainerView.layer.borderColor = UIColor.yellow.cgColor
            animatedContainerView.layer.borderWidth = 4
            toView.layer.borderColor = UIColor.red.cgColor
            toView.layer.borderWidth = 2
        }
        containerView.addSubview(animatedContainerView)
        
        let animatedContainerHConstraint = animatedContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor,
                                                                                                   constant: fromCardFrame.midX - containerView.bounds.width/2)
        let animatedContainerVConstraint: NSLayoutConstraint = {
            switch params.settings.cardVerticalExpandingStyle {
            case .fromCenter:
                return animatedContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor,
                                                                      constant: fromCardFrame.midY - containerView.bounds.height/2)
            case .fromTop:
                return animatedContainerView.topAnchor.constraint(equalTo: containerView.topAnchor,
                                                                  constant: fromCardFrame.minY + params.settings.cardContainerInsets.top)
            }
        }()
        
        do /* Fix centerX/width/height of animated container to container */ {
            NSLayoutConstraint.activate([
                animatedContainerVConstraint,
                animatedContainerHConstraint,
                animatedContainerView.widthAnchor.constraint(equalToConstant: containerView.bounds.width - (params.settings.cardContainerInsets.left + params.settings.cardContainerInsets.right)),
                animatedContainerView.heightAnchor.constraint(equalToConstant: containerView.bounds.height - (params.settings.cardContainerInsets.top + params.settings.cardContainerInsets.bottom))
            ])
        }
        
        animatedContainerView.addSubview(toView)
        toView.translatesAutoresizingMaskIntoConstraints = false
        
        //        let weirdCardToAnimatedContainerTopAnchor: NSLayoutConstraint
        
        do /* Pin top (or center Y) and center X of the card, in animated container view */ {
            let verticalConstraint: NSLayoutConstraint = {
                switch params.settings.cardVerticalExpandingStyle {
                case .fromCenter:
                    return toView.centerYAnchor.constraint(equalTo: animatedContainerView.centerYAnchor)
                case .fromTop:
                    return toView.topAnchor.constraint(equalTo: animatedContainerView.topAnchor)
                }
            }()
            let cardConstraints = [
                verticalConstraint,
                toView.centerXAnchor.constraint(equalTo: animatedContainerView.centerXAnchor)
            ]
            NSLayoutConstraint.activate(cardConstraints)
        }
        let cardWidthConstraint = toView.widthAnchor.constraint(equalToConstant: fromCardFrame.width - (params.settings.cardContainerInsets.left + params.settings.cardContainerInsets.right))
        let cardHeightConstraint = toView.heightAnchor.constraint(equalToConstant: fromCardFrame.height - (params.settings.cardContainerInsets.top + params.settings.cardContainerInsets.bottom))
        NSLayoutConstraint.activate([cardWidthConstraint, cardHeightConstraint])
        
        toView.layer.cornerRadius = params.settings.cardCornerRadius
        
        // -------------------------------
        // Final preparation
        // -------------------------------
        params.fromCell.isHidden = true
        params.fromCell.resetTransform()
        
        let topTemporaryFix = cardDetailViewController.cardContentView.topAnchor.constraint(equalTo: cardDetailViewController.view.topAnchor, constant: 0)
        topTemporaryFix.isActive = params.settings.isEnabledWeirdTopInsetsFix
        
        containerView.layoutIfNeeded()
        
        // ------------------------------
        // 1. Animate container bouncing up
        // ------------------------------
        func animateContainerBouncingUp() {
            animatedContainerVConstraint.constant = finalFrame.midY - containerView.bounds.height/2 + finalFrame.minY
            animatedContainerHConstraint.constant = 0
            containerView.layoutIfNeeded()
        }
        
        // ------------------------------
        // 2. Animate cardDetail filling up the container
        // ------------------------------
        func animateCardDetailViewSizing() {
            cardDetailViewController.didStartPresentAnimationProgress()
            
            cardWidthConstraint.constant = finalFrame.width + (params.settings.cardContainerInsets.left + params.settings.cardContainerInsets.right)
            cardHeightConstraint.constant = finalFrame.height + (params.settings.cardContainerInsets.top + params.settings.cardContainerInsets.bottom)
            toView.layer.cornerRadius = params.settings.detailsCornerRadius
            
            params.settings.additionalCardViewAnimations?(cardDetailViewController.cardContentView, true)
            
            containerView.layoutIfNeeded()
        }
        
        func completeEverything() {
            // Remove temporary `animatedContainerView`
            //            animatedContainerView.removeConstraints(animatedContainerView.constraints)
            animatedContainerView.removeFromSuperview()
            
            // Re-add to the top
            containerView.addSubview(toView)
            
            toView.removeConstraints([topTemporaryFix, cardWidthConstraint, cardHeightConstraint])
            
            //            cardDetailView.edges(to: container)
            toView.translatesAutoresizingMaskIntoConstraints = true
            toView.frame = finalFrame
            
            // No longer need the bottom constraint that pins bottom of card content to its root.
            //screens.cardDetail.cardBottomToRootBottomConstraint.isActive = false
            cardDetailViewController.scrollView?.isScrollEnabled = true
            
            let success = !ctx.transitionWasCancelled
            ctx.completeTransition(success)
            
            cardDetailViewController.didFinishPresentAnimationProgress()
        }
        
        baseAnimator.addAnimations {
            
            // Spring animation for bouncing up
            animateContainerBouncingUp()
            
            // Linear animation for expansion
            let cardExpanding = UIViewPropertyAnimator(duration: baseAnimator.duration * 0.6, curve: .linear) {
                animateCardDetailViewSizing()
            }
            cardExpanding.startAnimation()
        }
        
        baseAnimator.addCompletion { (_) in
            completeEverything()
        }
        
        self.animator = baseAnimator
    }
}
