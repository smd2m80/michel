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


class ToucheEventTextView: UITextView {

    var cFLAG = false
      
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//            print("TE-Began")
            if let next = next {
                next.touchesBegan(touches , with: event)
            } else {
                super.touchesBegan(touches , with: event)
            }
        }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let next = next {
//            next.touchesEnded(touches , with: event)
//        } else {
//            super.touchesEnded(touches , with: event)
//        }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let next = next {
//            next.touchesCancelled(touches, with: event)
//        } else {
//            super.touchesCancelled(touches, with: event)
//        }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let next = next {
//            next.touchesMoved(touches, with: event)
//        } else {
//            super.touchesMoved(touches, with: event)
//        }
//    }
}
