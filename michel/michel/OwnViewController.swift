//
//  ScrollOwnViewController.swift
//  michel
//
//  Created by smd on 2020/12/28.
//

import UIKit

//WebKit Frameworkをインポート
import WebKit

import CoreMotion
import simd
import CoreML

class OwnViewController: UIViewController, UIGestureRecognizerDelegate {

    //WKWebviewの宣言
    var _webkitview: WKWebView?

    var cFLAG = false

    let py = PySensors()

    override func viewDidLoad() {
        py.startSensorUpdates(intervalSeconds: 0.01) // 100Hz

        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //WebKitのインスタンス作成
        self._webkitview = WKWebView()

        //WebKitをviewに紐付け
        self.view = self._webkitview!

        // ジェスチャーを生成(今回はタップ・スワイプ・長押し)
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OwnViewController.tap(_:)))
        let panGesture:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(OwnViewController.pan(_:)))
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(OwnViewController.longPress(_:)))

        // デリゲートをセット
        tapGesture.delegate = self;
        panGesture.delegate = self;
        longPressGesture.delegate = self;

        // WebViewに追加
        self._webkitview!.addGestureRecognizer(tapGesture)
        self._webkitview!.addGestureRecognizer(panGesture)
        self._webkitview!.addGestureRecognizer(longPressGesture)

        //URLを作って表示
        var url:NSURL
        url = NSURL(string:"https://ja.wikipedia.org/wiki/%E3%83%8B%E3%82%B3%E3%83%A9%E3%82%A6%E3%82%B9%E3%83%BB%E3%82%B3%E3%83%9A%E3%83%AB%E3%83%8B%E3%82%AF%E3%82%B9")!

        let req:NSURLRequest;

        req = NSURLRequest(url:url as URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)

        self._webkitview!.load(req as URLRequest)

        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return true
    }

    @objc func tap(_ sender: UITapGestureRecognizer){
        //タップ時の処理
        print("tap")
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

//        let py = PySensors()
        if py.getCoremlOutputpy(compDouble)==0{
            cFLAG = true
            print("Pybegan: cope")
//                let activeUrl: URL? = self._webkitview?.url
//                let url = activeUrl?.absoluteString
//    //                        print(url!)
//                UIPasteboard.general.string = url
//                alert(title: "リンクをコピーしました", message: "")
            
        }else{
            cFLAG = false
            print("Pybegan: nomal")
        }
        
    }

    @objc func pan(_ sender: UITapGestureRecognizer){
        //スワイプ時の処理
//        print("PAAAAAAAAAAAAN")
        switch(sender.state) {
        case .began:
//            print("panBegan")

            break
                
        case .possible:
//            print("possible")
            break
        case .changed:
//            print("changed")
            break
        case .ended:
//            print("end")
            break
        case .cancelled:
            break
        case .failed:
            break
        @unknown default:
            break
        }
    }

    @objc func longPress(_ sender: UITapGestureRecognizer){
        //長押し時の処理
        print("longPress")
    }

}


//
//import UIKit
//import WebKit
//import CoreMotion
//import simd
//import CoreML
//
//class OwnViewController: UIViewController, WKUIDelegate {
//
//    var webView: WKWebView!
//
//    let motionManager = CMMotionManager()
//    var cFLAG = false
//
//    var attitude = SIMD3<Double>.zero
//    var gyro = SIMD3<Double>.zero
//    var acc = SIMD3<Double>.zero
//
//    let xmsLen = 30
//
//    let featVal = 66
//    let pymodel = try! PyMlyokomtb200ms_predSTD(configuration: MLModelConfiguration())
//    let stdModel = try! smdskjk200ms_std(configuration: MLModelConfiguration())
//
//    var rawSensors = PySensors.Sensors()
//    var rawdiff = PySensors.RawDiff()
//
////    override func loadView() {
////        let webConfiguration = WKWebViewConfiguration()
////        webView = WKWebView(frame: .zero, configuration: webConfiguration)
////        webView.uiDelegate = self
//////        view = webView
////    }
//
//    override func viewDidLoad() {
////
////        guard let windowScene = UIApplication.shared.connectedScenes
////                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
////        let window = SelfWindow(windowScene: windowScene)
////        window.rootViewController = UIViewController()
////        window.windowLevel = UIWindow.Level.alert + 1
////        window.makeKeyAndVisible()
////
////
////
////        for win in UIApplication.shared.windows {
////            if win.isKeyWindow {
////                print("this is key: ",win)
////            }else{
////                print(win)
////            }
////            print(win.windowLevel)
////        }
//
//        // WKWebViewを生成
//        webView = WKWebView(frame: view.frame)
//        // WKWebViewをViewControllerのviewに追加する
//        view.addSubview(webView)
//
//        let overView = UIView()
//        webView.addSubview(overView)
//        // リクエストを生成
//        let request = URLRequest(url: URL(string: "https://www.google.co.jp/")!)
//        // リクエストをロードする
//        webView.load(request)
//
//        let myPanGesture = UIPanGestureRecognizer(
//                    target: self,
//                    action: #selector(panGesture(_:))
//                )
////        self.overView.addGestureRecognizer(myPanGesture)
//
//    }
//
//    @objc func panGesture(_ gesture: UIPanGestureRecognizer){
//            switch(gesture.state) {
//            case .began:
//                print("panbegan")
////                PySensors.gyroArray = gyroArray.suffix(xmsLen).map { $0 }
////                PySensors.accArray = accArray.suffix(xmsLen).map { $0 }
////
////                if getCoremlOutput()=="cope"{
////                    cFLAG = true
////                    print("pan: cope")
////                    scrollView.isScrollEnabled = false
////    //                self.view.removeGestureRecognizer(self.myPanGesture)
////                    print(UIGestureRecognizer.self)
////                }else{
////                    cFLAG = false
////                    print("pan: nomal")
////                    scrollView.isScrollEnabled = true
////                    print(UIGestureRecognizer.self)
////                }
//                //開始時の処理
//                break
//
//            case .changed:
//                print("panMove")
//                //ドラッグ中の処理
//                break
//
//            case .ended:
//                print("panend")
//                //ドラッグ終了時の処理
//                break
//            default:
//                break
//            }
//        }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("VcB")
//        self.next?.touchesBegan(touches, with: event)
//    }
//
//}
//
//
//
//
////override func loadView() {
////    let webConfiguration = WKWebViewConfiguration()
////    webView = OwnWKWebView(frame: .zero, configuration: webConfiguration) as! OwnWKWebView
////    webView.uiDelegate = self
////    view = webView
////}
////
////override func viewDidLoad() {
//////        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
////
////    super.viewDidLoad()
////    let myURL = URL(string:"https://ja.wikipedia.org/wiki/%E3%83%8B%E3%82%B3%E3%83%A9%E3%82%A6%E3%82%B9%E3%83%BB%E3%82%B3%E3%83%9A%E3%83%AB%E3%83%8B%E3%82%AF%E3%82%B9")
////    let myRequest = URLRequest(url: myURL!)
////    webView.load(myRequest)
////
////
////    Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(OwnViewController.didTimer), userInfo: nil, repeats: true)
////
////    var window = SelfWindow()
////    for win in UIApplication.shared.windows {
////        print(win)
////        print(win.windowLevel)
////        if win.isKeyWindow {
////            print("This is key")
////        }
////    }
////}
////@objc private func didTimer() {
////        if let myWindow = (UIApplication.shared.delegate as? AppDelegate)?.myWindow {
////            if myWindow.allTouches.isEmpty != true{
////                print("タッチ")
////            }
////        }
////    }
