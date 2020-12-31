//
//  OwnWKWebView.swift
//  michel
//
//  Created by smd on 2020/12/28.
//

import UIKit
import WebKit

class OwnWKWebView : WKWebView{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ownwkvB")
        self.next?.touchesBegan(touches, with: event)
    }
}

