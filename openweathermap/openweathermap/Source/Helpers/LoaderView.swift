//
//  LoaderView.swift
//  openweathermap
//
//  Created by Constantine Likhachov on 23.12.2020.
//

import UIKit

class LoaderView: UIView {
    
    static let sharedInstance = LoaderView()
    
    private let lineWidth: CGFloat = 6.0
    private let circleSize: CGSize = CGSize(width: 150.0, height: 150.0)
    private var circleLayer : CAShapeLayer?
    
    //==============================================================================
    
    override init(frame: CGRect) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentWindow = appDelegate.coordinator.window!
        super.init(frame: currentWindow.frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //==============================================================================
    
    private func setup() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentWindow = appDelegate.coordinator.window!
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.circleLayer = CAShapeLayer()
        self.circleLayer?.strokeColor = UIColor.gray.withAlphaComponent(0.7).cgColor
        self.circleLayer?.fillColor = UIColor.clear.cgColor
        self.circleLayer?.lineCap = CAShapeLayerLineCap.round
        self.circleLayer?.lineWidth = lineWidth
        let position = CGPoint(x: (currentWindow.frame.width - circleSize.width)/2.0, y: (currentWindow.frame.height - circleSize.height)/2.0)
        self.circleLayer?.frame = CGRect(origin: position, size: circleSize)
        self.layer.addSublayer(self.circleLayer!)
    }
    
    //==============================================================================
    
    private func drawBackgroundCircle(partial : Bool) {
        let startAngle : CGFloat = CGFloat.pi / CGFloat(2.0)
        var endAngle : CGFloat = (2.0 * CGFloat.pi) + startAngle
        
        let center : CGPoint = CGPoint(x: circleSize.width / 2,y: circleSize.height / 2)
        let radius : CGFloat = (CGFloat(circleSize.width) - lineWidth) / CGFloat(2.0)
        
        let processBackgroundPath : UIBezierPath = UIBezierPath()
        processBackgroundPath.lineWidth = lineWidth
        
        if (partial) {
            endAngle = (1.75 * CGFloat.pi) + startAngle
        }
        processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        circleLayer?.path = processBackgroundPath.cgPath;
    }
    
    //==============================================================================
    
    func start() {
        self.alpha = 0
        self.drawBackgroundCircle(partial: true)
        let rotationAnimation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2.0)
        rotationAnimation.duration = 1;
        rotationAnimation.isCumulative = true;
        rotationAnimation.repeatCount = HUGE;
        circleLayer?.add(rotationAnimation, forKey: "rotationAnimation")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentWindow = appDelegate.coordinator.window!
        currentWindow.addSubview(self)
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    //==============================================================================
    
    func stop() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { (finish) in
            self.circleLayer?.removeAllAnimations()
            self.removeFromSuperview()
        }
    }
    
    //==============================================================================
    
}
