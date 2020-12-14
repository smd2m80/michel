import UIKit
 
class ScrollImageViewController: UIViewController {
 
    // 画像インスタンス
    let imageBag = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Screen Size の取得
        let screenWidth:CGFloat = view.frame.size.width
        let screenHeight:CGFloat = view.frame.size.height

        // ハンドバッグの画像を設定
        imageBag.image = UIImage(named: "3")
        // オリジナル画像のサイズからアスペクト比を計算
        let aspectScale = imageBag.image!.size.height / imageBag.image!.size.width
        // widthからアスペクト比を元にリサイズ後のサイズを取得
        let resizedSize = CGSize(width: screenWidth, height: screenWidth * CGFloat(Double(aspectScale)))
        // 画像のフレームを設定
        imageBag.frame = CGRect(x:0, y:0, width:resizedSize.width, height:resizedSize.height)
        // 画像をスクリーン中央に設定
        imageBag.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        // タッチ操作を enable
        imageBag.isUserInteractionEnabled = true
        self.view.addSubview(imageBag)
        
    }
    
    // 画面にタッチで呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        
    }
    
    //　ドラッグ時に呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タッチイベントを取得
        let touchEvent = touches.first!
        
        // ドラッグ前の座標, Swift 1.2 から
        let preDx = touchEvent.previousLocation(in: self.view).x
        let preDy = touchEvent.previousLocation(in: self.view).y
        
        // ドラッグ後の座標
        let newDx = touchEvent.location(in: self.view).x
        let newDy = touchEvent.location(in: self.view).y
        
        // ドラッグしたx座標の移動距離
        let dx = newDx - preDx
        print("x:\(dx)")
        
        // ドラッグしたy座標の移動距離
        let dy = newDy - preDy
        print("y:\(dy)")
        
        // 画像のフレーム
        var viewFrame: CGRect = imageBag.frame
        
        // 移動分を反映させる
//        viewFrame.origin.x += dx
        viewFrame.origin.y += dy
        
        imageBag.frame = viewFrame
        
        self.view.addSubview(imageBag)
        
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
 
}
