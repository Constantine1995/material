//
//  FocusedButton.swift
//  InStat
//
//  Created by Constantine Likhachov on 05.07.2021.
//  Copyright © 2021 Natife. All rights reserved.
//

import UIKit

@IBDesignable
class FocusedButton: UIButton {
    
    public var animationDuration: TimeInterval = 0.2
    @IBInspectable public var focusedScaleFactor: CGFloat = 1.08
    @IBInspectable public var isBackgroundFocus: Bool = false
    
    public var shadowOffSetFocused: CGSize = CGSize(width: 0, height: 27)
    private let colorBackground = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.5)
    
    private func applyFocusedStyle() {
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                [weak self] in
                self?.updateView()
            },
            completion: nil)
    }
    
    private func applyUnfocusedStyle() {
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                [weak self] in
                self?.updateView()
            },
            completion: nil)
    }
    
    private func updateView() {
        isBackgroundFocus ? setBackgorund() : setTransform()
    }
    
    private func setTransform() {
        transform = isFocused ?
            CGAffineTransform(scaleX: focusedScaleFactor, y: focusedScaleFactor)
            : CGAffineTransform.identity
    }
    
    private func setBackgorund() {
        backgroundColor = isFocused ? colorBackground : .clear
        layer.cornerRadius = frame.width / 2
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.isFocused ? self.applyFocusedStyle() : self.applyUnfocusedStyle()
        }, completion: nil)
    }
    
    override open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.first?.type == .select else {
            return super.pressesBegan(
                presses,
                with: event
            )
        }
        
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                [weak self] in
                guard let self = self else { return }
                self.transform = CGAffineTransform.identity
                self.layer.shadowOffset = CGSize(width: 0, height: 10)
            })
    }
    
    override open func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.first?.type == .select else {
            return super.pressesCancelled(
                presses,
                with: event
            )
        }
        guard isFocused else { return }
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                [weak self] in
                guard let self = self else { return }
                self.transform = CGAffineTransform(
                    scaleX: self.focusedScaleFactor,
                    y: self.focusedScaleFactor
                )
                self.layer.shadowOffset = self.shadowOffSetFocused
            })
    }
    
    override open func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.first?.type == .select else {
            return super.pressesEnded(
                presses,
                with: event
            )
        }
        guard isFocused else { return }
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                [weak self] in
                guard let self = self else { return }
                self.transform = CGAffineTransform(
                    scaleX: self.focusedScaleFactor,
                    y: self.focusedScaleFactor
                )
                self.layer.shadowOffset = self.shadowOffSetFocused
            })
    }
}
