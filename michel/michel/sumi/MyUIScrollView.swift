//
//  ToucheEventTextView.swift
//  panApp
//
//  Created by smd on 2020/09/25.
//  Copyright © 2020 smd. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import simd

import CoreML


class MyUIScrollView: UIScrollView {
      
    var mybeganX : CGFloat!
    var mybeganY : CGFloat!
    var mymidX : CGFloat!
    var mymidY : CGFloat!
    var myendX : CGFloat!
    var myendY : CGFloat!

    var testDraw : UIView!
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
//        print("touchesBeganonView")
        
        let touchEvent = touches.first!
        mybeganX = touchEvent.location(in: self).x
        mybeganY = touchEvent.location(in: self).y
        print("beganLocation on View:",mybeganX,mybeganY)
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesMoved(touches, with: event)
//        print("touchesMoved")
        let touchEvent = touches.first!

        for view in self.subviews{
            if view.tag == 1{
                view.removeFromSuperview()
            }
        }
        self.isScrollEnabled = false
        // ドラッグ後の座標
        mymidX = touchEvent.location(in: self).x
        mymidY = touchEvent.location(in: self).y
        testDraw = TestDraw(frame: CGRect(x: min(mybeganX, mymidX),y: min(mybeganY, mymidY), width: abs(mybeganX - mymidX), height: abs(mybeganY - mymidY)))
        // viewを透明に
        testDraw.isOpaque = false
        testDraw.tag = 1
        self.addSubview(testDraw)

    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("touchesEndedonView")
        let touchEvent = touches.first!
        // ドラッグ後の座標
        myendX = touchEvent.location(in: self).x
        myendY = touchEvent.location(in: self).y
//        print("endLocation on view:",myendX,myendY)
        
        testDraw = TestDraw(frame: CGRect(x: min(mybeganX, myendX),y: min(mybeganY, myendY), width: abs(mybeganX - myendX), height: abs(mybeganY - myendY)))
//        self.isOpaque = false
        for view in self.subviews{
            if view.tag == 1{
                view.removeFromSuperview()
                print("TAG: ",view.tag)
            }
        }
        testDraw.tag = 2
        testDraw.isOpaque = false
        self.addSubview(testDraw)
        
//        let image = getScreenShot(windowFrame: CGRect(x: min(mybeganX, myendX),y: min(mybeganY, myendY), width: abs(mybeganX - myendX), height: abs(mybeganY - myendY)))
//        performSegue(withIdentifier: "popup", sender: nil)
        
        self.next?.touchesEnded(touches, with: event)
        self.isScrollEnabled = true

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            for view in self.subviews{
                if view.tag == 2{
                    view.removeFromSuperview()
                }
            }
        }
        
        
    }
    
    func getScreenShot(windowFrame: CGRect) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        capturedImage.draw(in: windowFrame)
        return capturedImage
    }
    

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let next = next {
            next.touchesCancelled(touches, with: event)
        } else {
            super.touchesCancelled(touches, with: event)
        }
    }
    
}
