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
    let model = try! MACby10_45_attNasi(configuration: MLModelConfiguration())
    var currentState = try? MLMultiArray(
        shape: [400 as NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let endLabel = UILabel() // ラベルの生成
    
    let featVal = 66
    let pymodel = try! PyMlyokomtb200ms_predSTD(configuration: MLModelConfiguration())
    let stdModel = try! smdskjk200ms_std(configuration: MLModelConfiguration())

    var rawSensors = Sensors()
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
        
        self.view.backgroundColor = .systemGray
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        // Labelの書式
        endLabel.frame = CGRect(x: 0, y: 40, width: UIScreen.main.bounds.size.width, height: 44) // 位置とサイズの指定
        endLabel.textAlignment = NSTextAlignment.center // 横揃えの設定
        endLabel.textColor = UIColor.black // テキストカラーの設定
        endLabel.font = UIFont(name: "HiraKakuProN-W6", size: 17) // フォントの設定
        endLabel.text = "start"
        self.view.addSubview(endLabel) // ラベルの追加
        
        textView.text = "I can easily conceive, most Holy Father, that as soon as some people learn that in this book which I have written concerning the revolutions of the heavenly bodies, I ascribe certain motions to the Earth, they will cry out at once that I and my theory should be rejected. For I am not so much in love with my conclusions as not to weigh what others will think about them, and although I know that the meditations of a philosopher are far removed from the judgment of the laity, because his endeavor is to seek out the truth in all things, so far as this is permitted by God to the human reason, I still believe that one must avoid theories altogether foreign to orthodoxy. Accordingly, when I considered in my own mind how absurd a performance it must seem to those who know that the judgment of many centuries has approved the view that the Earth remains fixed as center in the midst of the heavens, if I should, on the contrary, assert that the Earth moves; I was for a long time at a loss to know whether I should publish the commentaries which I have written in proof of its motion, or whether it were not better to follow the example of the Pythagoreans and of some others, who were accustomed to transmit the secrets of Philosophy not in writing but orally, and only to their relatives and friends, as the letter from Lysis to Hipparchus bears witness. They did this, it seems to me, not as some think, because of a certain selfish reluctance to give their views to the world, but in order that the noblest truths, worked out by the careful study of great men, should not be despised by those who are vexed at the idea of taking great pains with any forms of literature except such as would be profitable, or by those who, if they are driven to the study of Philosophy for its own sake by the admonitions and the example of others, nevertheless, on account of their stupidity, hold a place among philosophers similar to that of drones among bees. Therefore, when I considered this carefully, the contempt which I had to fear because of the novelty and apparent absurdity of my view, nearly induced me to abandon utterly the work I had begun.\n My friends, however, in spite of long delay and even resistance on my part, withheld me from this decision. First among these was Nicolaus Schonberg, Cardinal of Capua, distinguished in all branches of learning. Next to him comes my very dear friend, Tidemann Giese, Bishop of Culm, a most earnest student, as he is, of sacred and, indeed, of all good learning. The latter has often urged me, at times even spurring me on with reproaches, to publish and at last bring to the light the book which had lain in my study not nine years merely, but already going on four times nine. Not a few other very eminent and scholarly men made the same request, urging that I should no longer through fear refuse to give out my work for the common benefit of students of Mathematics. They said I should find that the more absurd most men now thought this theory of mine concerning the motion of the Earth, the more admiration and gratitude it would command after they saw in the publication of my commentaries the mist of absurdity cleared away by most transparent proofs. So, influenced by these advisors and this hope, I have at length allowed my friends to publish the work, as they had long besought me to do.\n But perhaps Your Holiness will not so much wonder that I have ventured to publish these studies of mine, after having taken such pains in elaborating them that I have not hesitated to commit to writing my views of the motion of the Earth, as you will be curious to hear how it occurred to me to venture, contrary to the accepted view of mathematicians, and well-nigh contrary to common sense, to form a conception of any terrestrial motion whatsoever. Therefore I would not have it unknown to Your Holiness, that the only thing which induced me to look for another way of reckoning the movements of the heavenly bodies was that I knew that mathematicians by no means agree in their investigations thereof. For, in the first place, they are so much in doubt concerning the motion of the sun and the moon, that they can not even demonstrate and prove by observation the constant length of a complete year; and in the second place, in determining the motions both of these and of the five other planets, they fail to employ consistently one set of first principles and hypotheses, but use methods of proof based only upon the apparent revolutions and motions. For some employ concentric circles only; others, eccentric circles and epicycles; and even by these means they do not completely attain the desired end. For, although those who have depended upon concentric circles have shown that certain diverse motions can be deduced from these, yet they have not succeeded thereby in laying down any sure principle, corresponding indisputably to the phenomena. These, on the other hand, who have devised systems of eccentric circles, although they seem in great part to have solved the apparent movements by calculations which by these eccentrics are made to fit, have nevertheless introduced many things which seem to contradict the first principles of the uniformity of motion. Nor have they been able to discover or calculate from these the main point, which is the shape of the world and the fixed symmetry of its parts; but their procedure has been as if someone were to collect hands, feet, a head, and other members from various places, all very fine in themselves, but not proportionate to one body, and no single one corresponding in its turn to the others, so that a monster rather than a man would be formed from them. Thus in their process of demonstration which they term a 'method', they are found to have omitted something essential, or to have included something foreign and not pertaining to the matter in hand. This certainly would never have happened to them if they had followed fixed principles; for if the hypotheses they assumed were not false, all that resulted therefrom would be verified indubitably. Those things which I am saying now may be obscure, yet they will be made clearer in their proper place."
        
        textView.frame = CGRect(x: 10, y: 90, width: UIScreen.main.bounds.size.width-20, height: UIScreen.main.bounds.size.height-100)
        textView.isEditable = false
        self.view.addSubview(textView)

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
        
        attArray.append(attitude)
        gyroArray.append(gyro)
        accArray.append(acc)

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

        attArray = attArray.suffix(xmsLen).map { $0 }
        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
        accArray = accArray.suffix(xmsLen).map { $0 }

        // py
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

        if getCoremlOutput()=="cope"{
            cFLAG = true
            print("began: cope")
        }else{
            cFLAG = false
            print("began: nomal")
        }
        if getCoremlOutputpy(compDouble)==0{
            cFLAG = true
            print("Pybegan: cope")
            endLabel.text = "cope"
            self.view.addSubview(endLabel)
            self.view.backgroundColor = .systemYellow
        }else{
            cFLAG = false
            print("Pybegan: nomal")
            endLabel.text = "nomal"
            self.view.addSubview(endLabel)
            self.view.backgroundColor = .systemBackground

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
                                                    MACby10_45_attNasiInput(accScalar: mlarrayAccScalar,accX: mlarrayAccX, accY: mlarrayAccY, accZ: mlarrayAccZ, gyroScalar : mlarrayGyroScalar,  gyroX: mlarrayGyroX, gyroY: mlarrayGyroY, gyroZ: mlarrayGyroZ, stateIn: currentState!))
        else {
                fatalError("Unexpected runtime error.")
        }

        print(output.label)
        return output.label
    }
    
    func getCoremlOutputpy(_ comp:Array<Any>) -> Int64{
        // store sensor data in array for CoreML model
        let dataNum = NSNumber(value:featVal)
        let mlarray = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        
        for index in 0...featVal-1 {
            mlarray[index] = comp[index] as! NSNumber
        }
//        print(mlarray)
        
        guard let stded = try? stdModel.prediction(input: smdskjk200ms_stdInput(input: mlarray))
        else {
            fatalError("Unexpected runtime error.STD")
        }
        
        guard let output = try? pymodel.prediction(input:
                                                    PyMlyokomtb200ms_predSTDInput(input: stded.transformed_features))
        else {
                fatalError("Unexpected runtime error.")
        }

        print(output.classLabel)
        return output.classLabel
    }
}
