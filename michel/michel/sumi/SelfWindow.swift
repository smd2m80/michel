import UIKit

class SelfWindow: UIWindow {

    var allTouches = Set<UITouch>()

    override func sendEvent(_ event: UIEvent) {

        if event.type == .touches {
            if let allTouches = event.allTouches {
                for touch in allTouches {
                    switch touch.phase {
                    case .began:
                        print("send, bSelf")
                        self.allTouches.insert(touch)
                    case .ended, .cancelled:
                        self.allTouches.remove(touch)
                    default:
                        break
                    }
                }
            }
        }

        super.sendEvent(event)

        //allTouches = Set<UITouch>(allTouches.filter({ $0.phase != .ended && $0.phase != .cancelled }))　これだとメモリ効率悪いかな
        allTouches.filter { $0.phase == .ended || $0.phase == .cancelled }.forEach { allTouches.remove($0) }
    }
}
