import UIKit
import CoreMotion
import simd
import CoreML

class TryModelsViewController: UIViewController {
        
    let motionManager = CMMotionManager()
    var attitude = SIMD3<Double>.zero
    var gyro = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero
    
    let endLabel = UILabel() // ラベルの生成


//    var attArray : [SIMD3<Double>] = []
//    var gyroArray : [SIMD3<Double>] = []
//    var accArray : [SIMD3<Double>] = []
    var cFLAG = false
    
    let xmsLen = 30
    
    let featVal = 66
    let model = try! PyMlyokomtb200ms_predSTD(configuration: MLModelConfiguration())
    let stdModel = try! smdskjk200ms_std(configuration: MLModelConfiguration())
    
    var attArray = Sensor()
    var gyroArray = Sensor()
    var accArray = Sensor()
    var diffaccArray = Sensor()
    var diffattArray = Sensor()
    var diffgyroArray = Sensor()
    var arrayMean = [Double](repeating: 0.0, count: 22)
    var arrayVar = [Double](repeating: 0.0, count: 22)
    var arrayMax = [Double](repeating: 0.0, count: 22)
    
    var rawSensors = Sensors()
    var diffSensors = Sensors()
    var rawdiff = RawDiff()
    
    class Sensor{
        lazy var x = Array(repeating: 0.0, count: 30)
        lazy var y = Array(repeating: 0.0, count: 30)
        lazy var z = Array(repeating: 0.0, count: 30)
        lazy var scalar = Array(repeating: 0.0, count: 30)
        
        func removeAll(){
            x.removeAll()
            y.removeAll()
            z.removeAll()
            scalar.removeAll()
        }
        func cut(_ len:Int){
            x = x.suffix(len).map { $0 }
            y = y.suffix(len).map { $0 }
            z = z.suffix(len).map { $0 }
            scalar = scalar.suffix(len).map { $0 }
        }
        func append(_ add:SIMD3<Double>){
            x = x.dropFirst(1).map { $0 }
            y = y.dropFirst(1).map { $0 }
            z = z.dropFirst(1).map { $0 }
            scalar = scalar.dropFirst(1).map { $0 }
            x.append(add.x)
            y.append(add.y)
            z.append(add.y)
            scalar.append(add.x * add.y * add.z)
        }
        func add(_ add:SIMD3<Double>){
            x.append(add.x)
            y.append(add.y)
            z.append(add.y)
            scalar.append(add.x * add.y * add.z)
        }

        func mean() -> Array<Double>{
            return [x.average, y.average, z.average, scalar.average]
        }
        func varian() -> Array<Any>{
            return [x.variance(x), y.variance(y), z.variance(z), scalar.variance(scalar)]
        }
        func max() -> Array<Double?>{
            return [x.max(), y.max(), z.max(), scalar.max()]
        }
        
        func minus() -> Sensor{
            var dif = SIMD3<Double>.zero
            let difSensor = Sensor()
            for (index,_) in x.enumerated() {
                if index>0{
                    dif.x = x[index] - x[index-1]
                    dif.y = y[index] - y[index-1]
                    dif.z = z[index] - z[index-1]
                    difSensor.append(dif)
                }
            }
//            difSensor.cut(29)
            return difSensor
        }
                
    }
    
    class Sensors{
        var att = Sensor()
        var gyro = Sensor()
        var acc = Sensor()
        func append(_ addAtt:SIMD3<Double>, _ addGyro: SIMD3<Double>, _ addAcc: SIMD3<Double>){
            att.append(addAtt)
            gyro.append(addGyro)
            acc.append(addAcc)
        }
        func add(_ addAtt:SIMD3<Double>, _ addGyro: SIMD3<Double>, _ addAcc: SIMD3<Double>){
            att.add(addAtt)
            gyro.add(addGyro)
            acc.add(addAcc)
        }
        func removeall(){
            att.removeAll()
            gyro.removeAll()
            acc.removeAll()
        }
        func cut(_ len: Int){
            att.cut(len)
            gyro.cut(len)
            acc.cut(len)
        }
        func minus() -> Sensors{
            let difSensors = Sensors()
            difSensors.att = att.minus()
            difSensors.gyro = gyro.minus()
            difSensors.acc = acc.minus()
            return difSensors
        }
        func mean() -> Array<Double>{
            var meanArray = [Double]()
            meanArray += att.mean()
            meanArray += gyro.mean()
            meanArray += acc.mean()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }
        func varian() -> Array<Any>{
            var meanArray = [Any]()
            meanArray += att.varian()
            meanArray += gyro.varian()
            meanArray += acc.varian()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }
        func max() -> Array<Double?>{
            var meanArray = [Double?]()
            meanArray += att.max()
            meanArray += gyro.max()
            meanArray += acc.max()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }

    }
    class RawDiff{
        var Raw = Sensors()
        var Diff = Sensors()
    }
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        // Labelの書式
        endLabel.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 44) // 位置とサイズの指定
        endLabel.textAlignment = NSTextAlignment.center // 横揃えの設定
        endLabel.textColor = UIColor.black // テキストカラーの設定
        endLabel.font = UIFont(name: "HiraKakuProN-W6", size: 17) // フォントの設定
        endLabel.text = "start"
        self.view.addSubview(endLabel) // ラベルの追加

//        // tapセンサー
//        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
//            target: self,
//            action: #selector(TextViewController.tapped(_:)))
//        // デリゲートをセット
//        tapGesture.delegate = self as? UIGestureRecognizerDelegate
//        self.view.addGestureRecognizer(tapGesture)

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
        
//        attArray.append(attitude)
//        gyroArray.append(gyro)
//        accArray.append(acc)

        rawSensors.append(attitude,gyro,acc)
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
    
//    @objc func tapped(_ sender: UITapGestureRecognizer){
////        print("tap catch")
//        if sender.state == .ended {
//
//        }
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

//        attArray = attArray.suffix(xmsLen).map { $0 }
//        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
//        accArray = accArray.suffix(xmsLen).map { $0 }
        rawSensors.cut(xmsLen)

        rawdiff.Raw = rawSensors
        rawdiff.Diff = rawSensors.minus()
        var compDouble = [Any]()

        print(rawdiff.Diff.att.x)
        compDouble += rawdiff.Raw.mean()
        compDouble += rawdiff.Diff.mean()
        compDouble += rawdiff.Raw.varian()
        compDouble += rawdiff.Diff.varian()
        compDouble += rawdiff.Raw.max() as Array<Any>
        compDouble += rawdiff.Diff.max() as Array<Any>
        print(compDouble)
        
        if getCoremlOutput(compDouble)==0{
            cFLAG = true
            print("began: cope")
            endLabel.text = "cope"
            self.view.addSubview(endLabel)
            self.view.backgroundColor = .systemYellow
        }else{
            cFLAG = false
            print("began: nomal")
            endLabel.text = "nomal"
            self.view.addSubview(endLabel)
            self.view.backgroundColor = .systemBackground

        }
//        print("began: ",getCoremlOutput())
    }
    
    func getCoremlOutput(_ comp:Array<Any>) -> Int64{
        // store sensor data in array for CoreML model
        let dataNum = NSNumber(value:featVal)
        let mlarray = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        
        for index in 0...featVal-1 {
            mlarray[index] = comp[index] as! NSNumber
        }
        print(mlarray)
        
        guard let stded = try? stdModel.prediction(input: smdskjk200ms_stdInput(input: mlarray))
        else {
            fatalError("Unexpected runtime error.STD")
        }
        
        guard let output = try? model.prediction(input:
                                                    PyMlyokomtb200ms_predSTDInput(input: stded.transformed_features))
        else {
                fatalError("Unexpected runtime error.")
        }

        print(output.classLabel)
        return output.classLabel
    }
    
    
}


extension Collection where Element: Numeric {
    /// Returns the total sum of all elements in the array
    var total: Element { return reduce(0, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    var average: Double {
        return isEmpty ? 0 : Double(total) / Double(count)
    }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    var average: Element {
        return isEmpty ? 0 : total / Element(count)
    }
}
extension Array where Element == Double{
    //総和
    //全体の各要素を足し合わせるだけ。
    func sum(_ array:[Double])->Double{
        return array.reduce(0,+)
    }
    //平均値
    //全体の総和をその個数で割る。
    func ave(_ array:[Double])->Double{
        return self.sum(array) / Double(array.count)
    }
    //分散
    //求め方が２つあるが、計算量が少ないと思われる方法を採用。
    //V=E[X^2]-E[X]^2が成立。
    func variance(_ array:[Double])->Double{
        let left=self.ave(array.map{pow($0, 2.0)})
        let right=pow(self.ave(array), 2.0)
        let count=array.count
        return (left-right)*Double(count/(count-1))
    }
    //標準偏差
    //これは分散の正の平方根。つまりS=√V
    func standardDeviation(_ array:[Double]) -> Double {
        return sqrt(self.variance(array))
    }
}
