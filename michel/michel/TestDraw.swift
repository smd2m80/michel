import UIKit
 
class TestDraw: UIView {
 
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
 
        // 矩形 -------------------------------------
        let rectangle = UIBezierPath(rect: rect)
        // stroke 色の設定
        UIColor.white.setStroke()
        // 塗りつぶし色の設定
        UIColor.clear.setFill()
        rectangle.fill()
        // ライン幅
        rectangle.lineWidth = 2
        // 描画
        rectangle.stroke()
        

    }
    
 
}
