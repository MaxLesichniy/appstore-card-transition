//
//  CardPresentationController.swift
//  Kickster
//
//  Created by Razvan Chelemen on 06/05/2019.
//  Copyright © 2019 appssemble. All rights reserved.
//

import UIKit

final class CardPresentationController: UIPresentationController {
    
    private lazy var visualEffectView = UIVisualEffectView(effect: nil)
    private lazy var dissmisTapGestureRecognizer: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissTapHandle(_:)))
        return gesture
    }()
    
    var settings: CardTransitionSettings?
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, settings: CardTransitionSettings?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.settings = settings
    }
    
    // Default is false.
    // And also means you can access only `.to` when present, and `.from` when dismiss (e.g., can touch only 'presented view').
    //
    // If true, the presenting view is removed and you have to add it during animation accessing `.from` key.
    // And you will have access to both `.to` and `.from` view. (In the typical .fullScreen mode)
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    override var shouldPresentInFullscreen: Bool {
        return false
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        
        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            let minEdge = min(containerView.bounds.width, containerView.bounds.height)
            let size = CGSize(width: minEdge * 0.8, height: containerView.bounds.height * 0.9)
            let frame = CGRect(origin: CGPoint(x: (containerView.frame.width - size.width)/2,
                                               y: (containerView.frame.height - size.height)/2),
                               size: size)
            return frame
        }
        
        return super.frameOfPresentedViewInContainerView
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        
        visualEffectView.frame = containerView!.bounds
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func presentationTransitionWillBegin() {
        let container = containerView!
        container.addSubview(visualEffectView)
        
        visualEffectView.addGestureRecognizer(dissmisTapGestureRecognizer)
        
        visualEffectView.alpha = 0.0
        if let settings = settings {
            visualEffectView.backgroundColor = settings.visualEffectColor
            visualEffectView.effect = settings.visualEffect
        }
        
        presentingViewController.beginAppearanceTransition(false, animated: false)
        presentedViewController.transitionCoordinator!.animate(alongsideTransition: { (ctx) in
            UIView.animate(withDuration: ctx.transitionDuration * 0.5) {
                self.visualEffectView.alpha = self.settings?.visualEffectAlpha ?? 1.0
            }
        }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        presentingViewController.endAppearanceTransition()
    }
    
    override func dismissalTransitionWillBegin() {
        presentingViewController.beginAppearanceTransition(true, animated: true)
        presentedViewController.transitionCoordinator!.animate(alongsideTransition: { (ctx) in
            UIView.animate(withDuration: ctx.transitionDuration * 0.3, delay: ctx.transitionDuration * 0.2, options: []) {
                self.visualEffectView.alpha = 0.0
            }
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        presentingViewController.endAppearanceTransition()
        if completed {
            visualEffectView.removeFromSuperview()
        }
    }
    
    // MARK: -
    
    @objc fileprivate func dismissTapHandle(_ sender: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
}
