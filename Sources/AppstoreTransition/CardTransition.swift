//
//  CardTransition.swift
//  Kickster
//
//  Created by Razvan Chelemen on 06/05/2019.
//  Copyright © 2019 appssemble. All rights reserved.
//

import UIKit

public class CardTransitionSettings {
    public var cardHighlightedFactor: CGFloat = 0.96
    public var cardCornerRadius: CGFloat = 8
    public var detailsCornerRadius: CGFloat = 16
    public var dismissalAnimationDuration = 0.6
    public var dismissalScrollViewContentOffset = CGPoint.zero
    public var visualEffect: UIVisualEffect? = UIBlurEffect(style: .regular)
    public var visualEffectColor: UIColor = .clear
    public var visualEffectAlpha: CGFloat = 1.0
    
    public enum CardVerticalExpandingStyle {
        /// Expanding card pinning at the top of animatingContainerView
        case fromTop
        /// Expanding card pinning at the center of animatingContainerView
        case fromCenter
    }
    
    public var cardVerticalExpandingStyle: CardVerticalExpandingStyle = .fromTop
    
    /// Without this, there'll be weird offset (probably from scrollView) that obscures the card content view of the cardDetailView.
    public var isEnabledWeirdTopInsetsFix = false
    
    /// Swipe from bottom should also closes the detail screen.
    public var isEnabledBottomClose = false
    
    /// If true, will draw borders on animating views.
    public var isEnabledDebugAnimatingViews = false
    
    /// If true, this will add a 'reverse' additional top safe area insets to make the final top safe area insets zero.
    public var isEnabledTopSafeAreaInsetsFixOnCardDetailViewController = true
    
    /// If true, will always allow user to scroll while it's animated.
    public var isEnabledAllowsUserInteractionWhileHighlightingCard = true
    
    public var cardContainerInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    
    public var additionalCardViewAnimations: ((UIView, Bool) -> Void)?
    
    public init() {
        
    }
    
}

public final class CardTransition: NSObject {
    
    let cell: CardCollectionViewCell
    let settings: CardTransitionSettings
        
    public init(cell: CardCollectionViewCell, settings: CardTransitionSettings = .init()) {
        // Freeze highlighted state (or else it will bounce back)
        cell.freezeAnimations()
        
        self.cell = cell
        self.settings = settings
        
        super.init()
    }
    
    private func params() -> CardAnimator.Params {
        // Get current frame on screen
        let currentCellFrame = cell.layer.presentation()!.frame
        
        // Convert current frame to screen's coordinates
        let cardPresentationFrameOnScreen = cell.superview!.convert(currentCellFrame, to: nil)
        
        // Get card frame without transform in screen's coordinates  (for the dismissing back later to original location)
        let cardFrameWithoutTransform = { () -> CGRect in
            let center = cell.center
            let size = cell.bounds.size
            let r = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return cell.superview!.convert(r, to: nil)
        }()
                
        return CardAnimator.Params(fromCardFrame: cardPresentationFrameOnScreen,
                                   fromCardFrameWithoutTransform: cardFrameWithoutTransform,
                                   fromCell: cell,
                                   settings: settings)
    }
    
}

extension CardTransition: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentCardAnimator(params: params())
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissCardAnimator(params: params())
    }
    
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    // IMPORTANT: Must set modalPresentationStyle to `.custom` for this to be used.
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting, settings: settings)
    }
    
}
