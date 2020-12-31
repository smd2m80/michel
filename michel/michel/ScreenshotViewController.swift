//
//  ScreenshotViewController.swift
//  michel
//
//  Created by smd on 2020/12/11.
//

import UIKit
import CoreMotion
import simd
import CoreML

class ScreenshotViewController: UIViewController{
    
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
    
    var beganX : CGFloat!
    var beganY : CGFloat!
    var endX : CGFloat!
    var endY : CGFloat!


    
    private let numberOfPages = 6
    
    @IBOutlet private weak var mainScrollView: UIScrollView!
    @IBOutlet private weak var pageControl: UIPageControl!
    /// 現在のページインデックス
    private var currentPage = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageControl()
        
        // tapセンサー
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ScreenshotViewController.tapped(_:)))
        // デリゲートをセット
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(tapGesture)

        startSensorUpdates(intervalSeconds: 0.01)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupMainScrollView()
        (0..<numberOfPages).forEach { page in
            let subScrollView = generateSubScrollView(at: page)
            mainScrollView.addSubview(subScrollView)
            let imageView = generateImageView(at: page)
            subScrollView.addSubview(imageView)
        }
    }
    
    private func setupPageControl() {
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPage
        // タップされたときのイベントハンドリングを設定
        pageControl.addTarget(
            self,
            action: #selector(didValueChangePageControl),
            for: .valueChanged
        )
    }
    
    private func setupMainScrollView() {
        mainScrollView.delegate = self
        mainScrollView.isPagingEnabled = true
        mainScrollView.showsVerticalScrollIndicator = false
        mainScrollView.showsHorizontalScrollIndicator = false
        // コンテンツ幅 = ページ数 x ページ幅
        mainScrollView.contentSize = CGSize(
            width: calculateX(at: numberOfPages),
            height: mainScrollView.bounds.height
        )
    }
    
    private func generateSubScrollView(at page: Int) -> UIScrollView {
        let frame = calculateSubScrollViewFrame(at: page)
        let subScrollView = UIScrollView(frame: frame)
        
        subScrollView.delegate = self
        subScrollView.maximumZoomScale = 3.0
        subScrollView.minimumZoomScale = 1.0
        subScrollView.showsHorizontalScrollIndicator = false
        subScrollView.showsVerticalScrollIndicator = false
        
        // ダブルタップされたときのイベントハンドリングを設定
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapSubScrollView(_:)))
        gesture.numberOfTapsRequired = 2
        subScrollView.addGestureRecognizer(gesture)
        
        return subScrollView
    }
    
    private func generateImageView(at page: Int) -> UIImageView {
        let frame = mainScrollView.bounds
        let imageView = UIImageView(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = image(at: page)
        
        return imageView
    }
    
    /// ページコントロールを操作された時
    @objc private func didValueChangePageControl() {
        currentPage = pageControl.currentPage
        let x = calculateX(at: currentPage)
        mainScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    /// サブスクロールビューがダブルタップされた時
    @objc private func didDoubleTapSubScrollView(_ gesture: UITapGestureRecognizer) {
        guard let subScrollView = gesture.view as? UIScrollView else { return }
        
        if subScrollView.zoomScale < subScrollView.maximumZoomScale {
            // タップされた場所を中心に拡大する
            let location = gesture.location(in: subScrollView)
            let rect = calculateRectForZoom(location: location, scale: subScrollView.maximumZoomScale)
            subScrollView.zoom(to: rect, animated: true)
        } else {
            subScrollView.setZoomScale(subScrollView.minimumZoomScale, animated: true)
        }
    }
    
    /// ページ幅 x position でX位置を計算
    private func calculateX(at position: Int) -> CGFloat {
        return mainScrollView.bounds.width * CGFloat(position)
    }
    
    /// スクロールビューのオフセット位置からページインデックスを計算
    private func calculatePage(of scrollView: UIScrollView) -> Int {
        let width = scrollView.bounds.width
        let offsetX = scrollView.contentOffset.x
        let position = (offsetX - (width / 2)) / width
        return Int(floor(position) + 1)
    }
    
    /// タップされた位置と拡大率から拡大後のCGRectを計算する
    private func calculateRectForZoom(location: CGPoint, scale: CGFloat) -> CGRect {
        let size = CGSize(
            width: mainScrollView.bounds.width / scale,
            height: mainScrollView.bounds.height / scale
        )
        let origin = CGPoint(
            x: location.x - size.width / 2,
            y: location.y - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }
    
    /// サブスクロールビューのframeを計算
    private func calculateSubScrollViewFrame(at page: Int) -> CGRect {
        var frame = mainScrollView.bounds
        frame.origin.x = calculateX(at: page)
        return frame
    }
    
    private func resetZoomScaleOfSubScrollViews(without exclusionSubScrollView: UIScrollView) {
        for subview in mainScrollView.subviews {
            guard
                let subScrollView = subview as? UIScrollView,
                subScrollView != exclusionSubScrollView
                else {
                    continue
            }
            subScrollView.setZoomScale(subScrollView.minimumZoomScale, animated: false)
        }
    }
    
    private func image(at page: Int) -> UIImage? {
        return UIImage(named: "\(page)")
    }
    

    @objc func tapped(_ sender: UITapGestureRecognizer){
        if sender.state == .ended {
        }
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

        gyroArray = gyroArray.suffix(xmsLen).map { $0 }
        accArray = accArray.suffix(xmsLen).map { $0 }

        if getCoremlOutput()=="cope"{
            cFLAG = true
            print("began: cope")
            mainScrollView.isScrollEnabled = false
        }else{
            cFLAG = false
            print("began: nomal")
            mainScrollView.isScrollEnabled = true
        }
        let touchEvent = touches.first!
        beganX = touchEvent.location(in: self.view).x
        beganY = touchEvent.location(in: self.view).y
        print("beganL: ",beganX,beganY)

    }
    
    
}






extension ScreenshotViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != mainScrollView { return }
        
        let page = calculatePage(of: scrollView)
        if page == currentPage { return }
        currentPage = page
        
        pageControl.currentPage = page
        
        // 他のすべてのサブスクロールビューの拡大率をリセット
        resetZoomScaleOfSubScrollViews(without: scrollView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first as? UIImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let imageView = scrollView.subviews.first as? UIImageView else { return }
        
        scrollView.contentInset = UIEdgeInsets(
            top: max((scrollView.frame.height - imageView.frame.height) / 2, 0),
            left: max((scrollView.frame.width - imageView.frame.width) / 2, 0),
            bottom: 0,
            right: 0
        )
    }
    
// ユーザが指でドラッグを開始した場合に呼び出されるデリゲートメソッド.
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//
//        pyM.gyroArray = pyM.gyroArray.suffix(pyM.xmsLen).map { $0 }
//        pyM.accArray = pyM.accArray.suffix(pyM.xmsLen).map { $0 }
//
//        if pyM.getCoremlOutput()=="cope"{
//            pyM.cFLAG = true
//            print("began: cope")
//            scrollView.isScrollEnabled = false
//        }else{
//            pyM.cFLAG = false
//            print("began: nomal")
//            scrollView.isScrollEnabled = true
//        }
//        print(#function)
//    }

    // ユーザがドラッグ後、指を離した際に呼び出されるデリゲートメソッド.
    // velocity = points / second.
    // targetContentOffsetは、停止が予想されるポイント？
    // pagingEnabledがYESの場合には、呼び出されません.
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        print(#function)
//    }

    // ユーザがドラッグ後、指を離した際に呼び出されるデリゲートメソッド.
    // decelerateがYESであれば、慣性移動を行っている.
    //
    // 指をぴたっと止めると、decelerateはNOになり、
    // その場合は「scrollViewWillBeginDecelerating:」「scrollViewDidEndDecelerating:」が呼ばれない？
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print(#function)
    }
}
