import UIKit
import CoreMotion
import simd
import CoreML
 
class ScrollBigImageViewController: UIViewController {
    
    let motionManager2 = CMMotionManager()
    var gyro = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero
    var gyroArray : [SIMD3<Double>] = []
    var accArray : [SIMD3<Double>] = []
    var cFLAG = false
    
    let xmsLen = 30
    let model = try! MACby10_45_attNasi(configuration: MLModelConfiguration())
    var currentState = try? MLMultiArray(
        shape: [400 as NSNumber],
        dataType: MLMultiArrayDataType.double)

    var isPy = true

    // UIScrollViewインスタンス生成
    var scrollView = MyUIScrollView()
    var tagViewB = 27
    var screenHeight:CGFloat!
    var screenWidth:CGFloat!
    
    var image = UIImage()
    
    var beganX : CGFloat!
    var beganY : CGFloat!
    var endX : CGFloat!
    var endY : CGFloat!
        
    override func viewDidLoad() {
        super.viewDidLoad()
 
        scrollView.tag = tagViewB
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz

        // 画面サイズ取得
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        // 表示窓のサイズと位置を設定
        scrollView.frame.size =
            CGSize(width: screenWidth, height: screenHeight)
        scrollView.center = self.view.center
        // 表示する画像
        let jellyfish:UIImage = UIImage(named:"5")!
        // 画像のサイズ
        let imgW = jellyfish.size.width
        let imgH = jellyfish.size.height
        // UIImageView 初期化
        let imageView = UIImageView(image: jellyfish)
        scrollView.addSubview(imageView)
        // UIScrollViewの大きさを画像サイズに設定
        scrollView.contentSize = CGSize(width: imgW, height: imgH)
        // スクロールの跳ね返り無し
        scrollView.bounces = false
        // ビューに追加
        self.view.addSubview(scrollView)
                
        self.view.isUserInteractionEnabled = true
//        let myPanGesture = UIPanGestureRecognizer(
//            target: self,
//            action: #selector(panGesture(_:))
//        )
////        self.scrollView.addGestureRecognizer(myPanGesture)
//
//        let tappedGesture = UIGestureRecognizer(
//            target: self,
//            action: #selector(tappedGesture(_:))
//        )
//        // デリゲートをセット
//        tappedGesture.delegate = self as? UIGestureRecognizerDelegate
////        self.scrollView.addGestureRecognizer(tappedGesture)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
        accArray = accArray.suffix(xmsLen).map { $0 }

        if getCoremlOutput()=="cope"{
            cFLAG = true
            print("began: cope")
            scrollView.isScrollEnabled = false
        }else{
            cFLAG = false
            print("began: nomal")
            scrollView.isScrollEnabled = true
        }
        let touchEvent = touches.first!
        beganX = touchEvent.location(in: self.view).x
        beganY = touchEvent.location(in: self.view).y
        print("beganL: ",beganX,beganY)

    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        let touchEvent = touches.first!
        print("end")
        // ドラッグ後の座標
        endX = touchEvent.location(in: self.view).x
        endY = touchEvent.location(in: self.view).y
        print("endL: ",endX,endY)

//        image = getScreenShot(windowFrame: self.view.bounds)
//        image = getScreenShot(windowFrame: CGRect(x: min(beganX, endX),y: min(beganY, endY), width: abs(beganX - endX), height: abs(beganY - endY)))
//        performSegue(withIdentifier: "popup", sender: nil)
        scrollView.isScrollEnabled = true

    }
    
    func getCoremlOutput() -> String{
        // store sensor data in array for CoreML model
        let dataNum = NSNumber(value:xmsLen)
        let mlarrayGyroX = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroY = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroZ = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroScalar = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccX = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccY = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccZ = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccScalar = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        
        for index in 0...xmsLen-1 {
            mlarrayGyroX[index] = gyroArray[index].x as NSNumber
            mlarrayGyroY[index] = gyroArray[index].y as NSNumber
            mlarrayGyroZ[index] = gyroArray[index].z as NSNumber
            mlarrayGyroScalar[index] = gyroArray[index].x*gyroArray[index].y*gyroArray[index].z as NSNumber
            mlarrayAccX[index] = accArray[index].x as NSNumber
            mlarrayAccY[index] = accArray[index].y as NSNumber
            mlarrayAccZ[index] = accArray[index].z as NSNumber
            mlarrayAccScalar[index] = accArray[index].x*accArray[index].y*accArray[index].z as NSNumber
        }
        
        guard let output = try? model.prediction(input:
                                                    MACby10_45_attNasiInput(accScalar: mlarrayAccScalar,accX: mlarrayAccX, accY: mlarrayAccY, accZ: mlarrayAccZ, gyroScalar : mlarrayGyroScalar,  gyroX: mlarrayGyroX, gyroY: mlarrayGyroY, gyroZ: mlarrayGyroZ, stateIn: currentState!))
        else {
                fatalError("Unexpected runtime error.")
        }
        print(output.label)
        return output.label
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
    
    func getScreenShot(windowFrame: CGRect) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.view.layer.render(in: context)
        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        capturedImage.draw(in: windowFrame)
        return capturedImage
    }
    
    
    func startSensorUpdates(intervalSeconds:Double) {
        if motionManager2.isDeviceMotionAvailable{
            motionManager2.deviceMotionUpdateInterval = intervalSeconds
            
            // start sensor updates
            motionManager2.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.getMotionData(deviceMotion: motion!)
                
            })
        }
    }
    func getMotionData(deviceMotion:CMDeviceMotion) {
        gyro.x = deviceMotion.rotationRate.x
        gyro.y = deviceMotion.rotationRate.y
        gyro.z = deviceMotion.rotationRate.z
        acc.x = deviceMotion.userAcceleration.x
        acc.y = deviceMotion.userAcceleration.y
        acc.z = deviceMotion.userAcceleration.z

        gyroArray.append(gyro)
        accArray.append(acc)
    }
    
}

extension ScrollBigImageViewController: UIScrollViewDelegate {
    // ユーザがドラッグ後、指を離した際に呼び出されるデリゲートメソッド.
    // velocity = points / second.
    // targetContentOffsetは、停止が予想されるポイント？
    // pagingEnabledがYESの場合には、呼び出されません.
    func scrollViewWillEndDragging(_ scrollView: MyUIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print(#function)
    }

    // ユーザがドラッグ後、指を離した際に呼び出されるデリゲートメソッド.
    // decelerateがYESであれば、慣性移動を行っている.
    //
    // 指をぴたっと止めると、decelerateはNOになり、
    // その場合は「scrollViewWillBeginDecelerating:」「scrollViewDidEndDecelerating:」が呼ばれない？
    func scrollViewDidEndDragging(_ scrollView: MyUIScrollView, willDecelerate decelerate: Bool) {
        print(#function)
    }
}



//    @objc func tappedGesture(_ gesture: UIGestureRecognizer){
//        switch(gesture.state) {
//        case .began:
//            //開始時の処理
//            print("tapedBEGAN")
//            break
//
//        case .changed:
//            print("tapedMOVE")
//            //ドラッグ中の処理
//            break
//
//        case .ended:
//            print("tapedEND")
//            //ドラッグ終了時の処理
//            break
//        default:
//            break
//        }
//    }
//
//    @objc func panGesture(_ gesture: UIPanGestureRecognizer){
//        switch(gesture.state) {
//        case .began:
//            print("panbegan")
//            gyroArray = gyroArray.suffix(xmsLen).map { $0 }
//            accArray = accArray.suffix(xmsLen).map { $0 }
//
//            if getCoremlOutput()=="cope"{
//                cFLAG = true
//                print("pan: cope")
//                scrollView.isScrollEnabled = false
////                self.view.removeGestureRecognizer(self.myPanGesture)
//                print(UIGestureRecognizer.self)
//            }else{
//                cFLAG = false
//                print("pan: nomal")
//                scrollView.isScrollEnabled = true
//                print(UIGestureRecognizer.self)
//            }
//            //開始時の処理
//            break
//
//        case .changed:
//            print("panMove")
//            //ドラッグ中の処理
//            break
//
//        case .ended:
//            print("panend")
//            //ドラッグ終了時の処理
//            break
//        default:
//            break
//        }
//    }
//
