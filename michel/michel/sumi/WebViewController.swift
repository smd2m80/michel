//
//  FirstViewController.swift
//  panApp
//
//  Created by smd on 2020/08/18.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit
import WebKit
import CoreMotion
import simd
import CoreML


class WebViewController: UIViewController, WKUIDelegate{

    var webView: WKWebView!
    
    let motionManager = CMMotionManager()
    var cFLAG = false

    var attitude = SIMD3<Double>.zero
    var gyro = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero

    let xmsLen = 30

    let featVal = 66
    let pymodel = try! PyMlyokomtb200ms_predSTD(configuration: MLModelConfiguration())
    let stdModel = try! smdskjk200ms_std(configuration: MLModelConfiguration())

    var rawSensors = PySensors.Sensors()
    var rawdiff = PySensors.RawDiff()
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        super.viewDidLoad()
        let myURL = URL(string:"https://ja.wikipedia.org/wiki/%E3%83%8B%E3%82%B3%E3%83%A9%E3%82%A6%E3%82%B9%E3%83%BB%E3%82%B3%E3%83%9A%E3%83%AB%E3%83%8B%E3%82%AF%E3%82%B9")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        // UITapGestureRecognizerでタップイベントを取るようにする
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1

        // このときUIGestureRecognizerDelegateに準拠したオブジェクトを設定する
        tapRecognizer.delegate = self
        webView.addGestureRecognizer(tapRecognizer)
        
    }
    

    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//    //           let touch = touches.first!
//            let accZ200msMin = accZ.suffix(10).min() ?? 0
//            print(accZ.suffix(20))
//
//            if (accZ200msMin < -0.15){
////                print("touch")
//                print(self.webView.url ?? "non")
//        }
//
//    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer){
        // py
        rawSensors.cut()

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

        if getCoremlOutputpy(compDouble)==0{
            cFLAG = true
            print("Pybegan: cope")
            let activeUrl: URL? = self.webView.url
            let url = activeUrl?.absoluteString
//                        print(url!)
            UIPasteboard.general.string = url
            alert(title: "リンクをコピーしました", message: "")
            
        }else{
            cFLAG = false
            print("Pybegan: nomal")
        }

        
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
    

    //アラート
    func alert(title: String, message: String)  {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}


extension WebViewController: UIGestureRecognizerDelegate {

    // MARK: UIGestureRecognizerDelegate

    // このgestureRecognizerをオーバーライドしてtrueにしないとサブビューではTapイベントを検知できない
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

