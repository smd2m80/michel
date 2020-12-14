import UIKit
import CoreMotion
import simd
import CoreML

class TextViewController: UIViewController {

//    @IBOutlet weak var textView: ToucheEventTextView!
    let textView = ToucheEventTextView()
        
    let motionManager = CMMotionManager()
    var attitude = SIMD3<Double>.zero
    var gyro = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero

    var attArray : [SIMD3<Double>] = []
    var gyroArray : [SIMD3<Double>] = []
    var accArray : [SIMD3<Double>] = []
    var cFLAG = false
    
    let xmsLen = 30
    let model = try! MACin100out300(configuration: MLModelConfiguration())
    var currentState = try? MLMultiArray(
        shape: [400 as NSNumber],
        dataType: MLMultiArrayDataType.double)

//    var start = Date()
//    var elapsed : Double = 0.0

    //いらんやつ
    var format = DateFormatter()    //日付を取得
    let csvManager = SensorDataCsvManager()
    var text = ""
    var DisplayX = 0
    var DisplayY = 0
    var tapLocation = CGPoint(x: 0, y: 0)
    var touchB = 0
    var touchM = 0
    var tapCount = 0
    var isTapped = 0
    var myCircleNum = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemFill
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        textView.text = "I can easily conceive, most Holy Father, that as soon as some people learn that in this book which I have written concerning the revolutions of the heavenly bodies, I ascribe certain motions to the Earth, they will cry out at once that I and my theory should be rejected. For I am not so much in love with my conclusions as not to weigh what others will think about them, and although I know that the meditations of a philosopher are far removed from the judgment of the laity, because his endeavor is to seek out the truth in all things, so far as this is permitted by God to the human reason, I still believe that one must avoid theories altogether foreign to orthodoxy. Accordingly, when I considered in my own mind how absurd a performance it must seem to those who know that the judgment of many centuries has approved the view that the Earth remains fixed as center in the midst of the heavens, if I should, on the contrary, assert that the Earth moves; I was for a long time at a loss to know whether I should publish the commentaries which I have written in proof of its motion, or whether it were not better to follow the example of the Pythagoreans and of some others, who were accustomed to transmit the secrets of Philosophy not in writing but orally, and only to their relatives and friends, as the letter from Lysis to Hipparchus bears witness. They did this, it seems to me, not as some think, because of a certain selfish reluctance to give their views to the world, but in order that the noblest truths, worked out by the careful study of great men, should not be despised by those who are vexed at the idea of taking great pains with any forms of literature except such as would be profitable, or by those who, if they are driven to the study of Philosophy for its own sake by the admonitions and the example of others, nevertheless, on account of their stupidity, hold a place among philosophers similar to that of drones among bees. Therefore, when I considered this carefully, the contempt which I had to fear because of the novelty and apparent absurdity of my view, nearly induced me to abandon utterly the work I had begun."
        
        textView.frame = CGRect(x: 10, y: 100, width: UIScreen.main.bounds.size.width-20, height: UIScreen.main.bounds.size.height-100)
        textView.isEditable = false
        self.view.addSubview(textView)

        // tapセンサー
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(TextViewController.tapped(_:)))
        // デリゲートをセット
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(tapGesture)

    }
       
    func startSensorUpdates(intervalSeconds:Double) {
        if motionManager.isDeviceMotionAvailable{
            motionManager.deviceMotionUpdateInterval = intervalSeconds
            
            // start sensor updates
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.getMotionData(deviceMotion: motion!)
                
            })
        }
    }
    func getMotionData(deviceMotion:CMDeviceMotion) {
        attitude.x = deviceMotion.attitude.pitch
        attitude.y = deviceMotion.attitude.roll
        attitude.z = deviceMotion.attitude.yaw
        gyro.x = deviceMotion.rotationRate.x
        gyro.y = deviceMotion.rotationRate.y
        gyro.z = deviceMotion.rotationRate.z
        acc.x = deviceMotion.userAcceleration.x
        acc.y = deviceMotion.userAcceleration.y
        acc.z = deviceMotion.userAcceleration.z
        
        // record sensor data
        if csvManager.isRecording {
//            format.dateFormat = "MMddHHmmssSSS"
            format.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmssSSS", options: 0, locale: Locale(identifier: "ja_JP"))

//            var text = ""
            text += format.string(from: Date()) + ","

            text += String(attitude.x) + ","
            text += String(attitude.y) + ","
            text += String(attitude.z) + ","
            text += String(gyro.x) + ","
            text += String(gyro.y) + ","
            text += String(gyro.z) + ","
            text += String(gyro.x * gyro.y * gyro.z) + ","
//            text += String(gravity.x) + ","
//            text += String(gravity.y) + ","
//            text += String(gravity.z) + ","
            text += String(acc.x) + ","
            text += String(acc.y) + ","
            text += String(acc.z) + ","
            text += String(acc.x * acc.y * acc.z) + ","

            text += String(DisplayX) + ","
            text += String(DisplayY) + ","
//            text += appDelegate.smallCirleX.description + ","
//            text += appDelegate.smallCirleY.description + ","

            text += tapLocation.x.description + ","
            text += tapLocation.y.description + ","

            text += String(touchB) + ","
            touchB = 0
            text += String(touchM) + ","
            touchM = 0
            text += String(isTapped) + ","
            isTapped = 0

            text += String(myCircleNum) + "\n"

            csvManager.addRecordText(addText: text)
        }
//        print(text)
        attArray.append(attitude)
        gyroArray.append(gyro)
        accArray.append(acc)


    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            if self.cFLAG{
                textView.selectAll(self)
            }else{
                // 選択を解除したい
                textView.selectedRange = NSRange()
            }
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer){
//        print("tap catch")
        if sender.state == .ended {
//            self.start = Date()

            attArray = attArray.suffix(xmsLen).map { $0 }
            gyroArray = gyroArray.suffix(xmsLen).map { $0 }
            accArray = accArray.suffix(xmsLen).map { $0 }

//            elapsed = Date().timeIntervalSince(start)
//            print("cutten: ",elapsed)

//            print("tapped: ",getCoremlOutput())

//            if getCoremlOutput()=="cope"{
//                cFLAG = true
//            }else{
//                cFLAG = false
//            }
//
//            textViewDidBeginEditing(textView)
//            textView.resignFirstResponder()

            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        attArray = attArray.suffix(xmsLen).map { $0 }
        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
        accArray = accArray.suffix(xmsLen).map { $0 }

        if getCoremlOutput()=="cope"{
            cFLAG = true
            print("began: cope")
        }else{
            cFLAG = false
            print("began: nomal")
        }
//        print("began: ",getCoremlOutput())

        textViewDidBeginEditing(textView)
        textView.resignFirstResponder()
        
       }
    
    func getCoremlOutput() -> String{
        // store sensor data in array for CoreML model
        let dataNum = NSNumber(value:xmsLen)
        let mlarrayAttX = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAttY = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAttZ = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroX = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroY = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroZ = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayGyroScalar = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccX = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccY = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccZ = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        let mlarrayAccScalar = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        
        for index in 0...xmsLen-1 {
            mlarrayAttX[index] = attArray[index].x as NSNumber
            mlarrayAttY[index] = attArray[index].y as NSNumber
            mlarrayAttZ[index] = attArray[index].z as NSNumber
            mlarrayGyroX[index] = gyroArray[index].x as NSNumber
            mlarrayGyroY[index] = gyroArray[index].y as NSNumber
            mlarrayGyroZ[index] = gyroArray[index].z as NSNumber
            mlarrayGyroScalar[index] = gyroArray[index].x*gyroArray[index].y*gyroArray[index].z as NSNumber
            mlarrayAccX[index] = accArray[index].x as NSNumber
            mlarrayAccY[index] = accArray[index].y as NSNumber
            mlarrayAccZ[index] = accArray[index].z as NSNumber
            mlarrayAccScalar[index] = accArray[index].x*accArray[index].y*accArray[index].z as NSNumber
        }
//        elapsed = Date().timeIntervalSince(start)
//        print("getCoreOut: ",elapsed)
        
        guard let output = try? model.prediction(input:
                                                    MACin100out300Input(accScalar: mlarrayAccScalar,accX: mlarrayAccX, accY: mlarrayAccY, accZ: mlarrayAccZ, attX: mlarrayAttX, attY: mlarrayAttY, attZ: mlarrayAttZ,  gyroScalar : mlarrayGyroScalar,  gyroX: mlarrayGyroX, gyroY: mlarrayGyroY, gyroZ: mlarrayGyroZ, stateIn: currentState!))
        else {
                fatalError("Unexpected runtime error.")
        }

        print(output.label)
        return output.label
    }
    
    
}
