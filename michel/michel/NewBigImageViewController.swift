import UIKit
import CoreMotion
import simd
import CoreML
 
class NewBigImageViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let py = PySensors()
    
    var isPy = true
    var cFLAG = false
    // UIScrollViewインスタンス生成
    var scrollView = UIScrollView()
    var tagViewB = 27
    var screenHeight:CGFloat!
    var screenWidth:CGFloat!
    
    var image = UIImage()
    
    var began : CGPoint!
    var end : CGPoint!
    var beganSC : CGPoint!
    var endSC : CGPoint!

    override func viewDidLoad() {
        py.startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        super.viewDidLoad()
 
        scrollView.tag = tagViewB
        
        // 画面サイズ取得
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        scrollView.frame.size =
            CGSize(width: screenWidth, height: screenHeight)
        scrollView.center = self.view.center
        // 表示する画像
        let jellyfish:UIImage = UIImage(named:"5")!
        let imgW = jellyfish.size.width
        let imgH = jellyfish.size.height
        let imageView = UIImageView(image: jellyfish)
        scrollView.addSubview(imageView)
        // UIScrollViewの大きさを画像サイズに設定
        scrollView.contentSize = CGSize(width: imgW, height: imgH)
        // スクロールの跳ね返り無し
        scrollView.bounces = false
//        self.view.addSubview(scrollView)
        self.view = self.scrollView
                
        self.view.isUserInteractionEnabled = true

        let panGesture:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        panGesture.delegate = self;
        self.scrollView.addGestureRecognizer(panGesture)

    }
    @objc func pan(_ sender: UITapGestureRecognizer){
        //スワイプ時の処理
//        print("PAAAAAAAAAAAAN")
        switch(sender.state) {
        case .began:
//            print("panBegan")
            py.rawSensors.cut()
            
            py.rawdiff.Raw = py.rawSensors
            py.rawdiff.Diff = py.rawSensors.minus()
            var compDouble = [Any]()

            print(py.rawdiff.Diff.att.x)
            compDouble += py.rawdiff.Raw.mean()
            compDouble += py.rawdiff.Diff.mean()
            compDouble += py.rawdiff.Raw.varian()
            compDouble += py.rawdiff.Diff.varian()
            compDouble += py.rawdiff.Raw.max() as Array<Any>
            compDouble += py.rawdiff.Diff.max() as Array<Any>

            if py.getCoremlOutputpy(compDouble)==0{
                cFLAG = true
                scrollView.isScrollEnabled = false

                began = sender.location(in: self.scrollView)
                beganSC = sender.location(in: self.scrollView.superview)
                print("PanCope: ",beganSC!)
            }else{
                cFLAG = false
                print("Panbegan: nomal")
                scrollView.isScrollEnabled = true
            }
            break
                
        case .possible:
//            print("possible")
            break
        case .changed:
            if cFLAG{
                for view in self.scrollView.subviews{
                    if view.tag == 1{
                        view.removeFromSuperview()
                    }
                }
                self.scrollView.isScrollEnabled = false
                // ドラッグ後の座標
                end = sender.location(in: self.scrollView)
                endSC = sender.location(in: self.scrollView.superview) //スクリーン上の座標
                let testDraw = TestDraw(frame: CGRect(x: min(began.x, end.x),y: min(began.y, end.y), width: abs(began.x - end.x), height: abs(began.y - end.y)))
                // viewを透明に
                testDraw.isOpaque = false
                testDraw.tag = 1
                self.scrollView.addSubview(testDraw)

            }

            break
        case .ended:
//            print("end")
            if cFLAG{
                image = getScreenShot(beganSC,endSC)
                
                performSegue(withIdentifier: "popup", sender: nil)
                
                scrollView.isScrollEnabled = true
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    for view in self.scrollView.subviews{
                        if view.tag == 1{
                            view.removeFromSuperview()
                        }
                    }
                }
            }

            break
        case .cancelled:
            break
        case .failed:
            break
        @unknown default:
            break
        }
    }
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return true
    }
    
    //segueが動作することをViewControllerに通知するメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        //segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "popup" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? PopupViewController
            // 3. １で用意した遷移先の変数に値を渡す
            next?.outputImage = self.image
        }
    }
        
    func getScreenShot(_ beganP: CGPoint, _ endP :CGPoint) -> UIImage {

        let drawFrame = CGRect(x: min(beganP.x, endP.x), y: min(beganP.y, endP.y), width: abs(beganP.x - endP.x), height: abs(beganP.y - endP.y))
        
        UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, false, 0.0)
        for view in self.scrollView.subviews{
            if view.tag == 1{
                view.isHidden = true
            }
        }
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        var makeImage = UIGraphicsGetImageFromCurrentImageContext()!  //スリーンショットがUIImage型で取得できる
        UIGraphicsEndImageContext()
        UIGraphicsBeginImageContextWithOptions(drawFrame.size, false, 0.0)
        makeImage.draw(at: CGPoint(x: -min(beganSC.x, endSC.x), y: -min(beganSC.y, endSC.y)))
        makeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        for view in self.scrollView.subviews{
            if view.tag == 1{
                view.isHidden = false
            }
        }
        return makeImage
    }

//    func updateContentInset() {
//        let widthInset = max((scrollView.frame.width - imageView.frame.width) / 2, 0)
//        let heightInset = max((scrollView.frame.height - imageView.frame.height) / 2, 0)
//        scrollView.contentInset = .init(top: heightInset,
//                                        left: widthInset,
//                                        bottom: heightInset,
//                                        right: widthInset)
//    }
}
    


extension NewBigImageViewController: UIScrollViewDelegate {

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
    }
}
