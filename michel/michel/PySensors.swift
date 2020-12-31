import UIKit
import CoreMotion
import simd
import CoreML

let xmsLen = 30

class PySensors{

    let featVal = 66
    let pymodel = try! PyMlyokomtb200ms_predSTD(configuration: MLModelConfiguration())
    let stdModel = try! smdskjk200ms_std(configuration: MLModelConfiguration())

    let motionManager = CMMotionManager()
    
    var attitude = SIMD3<Double>.zero
    var gyro = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero


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
        func cut(){
            x = x.suffix(xmsLen).map { $0 }
            y = y.suffix(xmsLen).map { $0 }
            z = z.suffix(xmsLen).map { $0 }
            scalar = scalar.suffix(xmsLen).map { $0 }
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
        func cut(){
            att.cut()
            gyro.cut()
            acc.cut()
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

        rawSensors.append(attitude,gyro,acc)

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
