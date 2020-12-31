import UIKit
import CoreMotion
import simd
import CoreML

class FifthViewController: UIViewController, UIGestureRecognizerDelegate {

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

    var image = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()

        startSensorUpdates(intervalSeconds: 0.01) // 100Hz

        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
                    target: self,
            action: #selector(self.tapped(_:)))
                
                // デリゲートをセット
                tapGesture.delegate = self
                
                self.view.addGestureRecognizer(tapGesture)
    }

    @objc func tapped(_ sender: UITapGestureRecognizer){
        if sender.state == .ended {
            gyroArray = gyroArray.suffix(xmsLen).map { $0 }
            accArray = accArray.suffix(xmsLen).map { $0 }

            if getCoremlOutput()=="cope"{
                cFLAG = true
                print("tapped: cope")
//                view.isScrollEnabled = false
            }else{
                cFLAG = false
                print("tapped: nomal")
//                view.isScrollEnabled = true
            }
            
            image = getScreenShot(windowFrame: self.view.bounds)
            performSegue(withIdentifier: "popup", sender: nil)

            
            
        }
    }

    //segueが動作することをViewControllerに通知するメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        //segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "PopupSegue" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? PopupViewController
            // 3. １で用意した遷移先の変数に値を渡す
            next?.outputImage = self.image
        }
    }
    
    func getScreenShot(windowFrame: CGRect) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.view.layer.render(in: context)
        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return capturedImage
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

        return output.label
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        print("began on Fifth")
//        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
//        accArray = accArray.suffix(xmsLen).map { $0 }
//
//        if getCoremlOutput()=="cope"{
//            cFLAG = true
//            print("began: cope")
////            view.isScrollEnabled = false
//        }else{
//            cFLAG = false
//            print("began: nomal")
////            view.isScrollEnabled = true
//        }
//
//
//        image = getScreenShot(windowFrame: self.view.bounds)
//        performSegue(withIdentifier: "PopupSegue", sender: nil)
    }

}
