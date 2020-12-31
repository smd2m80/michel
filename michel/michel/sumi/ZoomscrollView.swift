import UIKit
import AVFoundation

class ZoomscrollView: UIView, UIScrollViewDelegate {
    
    var scrollView: UIScrollView! = nil
    var imageView: UIImageView! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        myInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        myInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = self.bounds
        imageView.frame = scrollView.bounds
    }
    
    /// 初期化
    func myInit() {
        
        // ScrollViewを作成
        scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.isScrollEnabled = true
        scrollView.zoomScale = 1
        scrollView.contentSize = self.bounds.size
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = UIColor.black
        self.addSubview(scrollView)
        
        // 画像を作成
        let image = UIImage(named: "3")
        imageView = UIImageView(image: image)
        imageView.isUserInteractionEnabled = true // 画像がタップできるようにする
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        scrollView.addSubview(imageView)
        
    }
    
    // MARK: - UIScrollViewDelegate
    
    /// ズームしたいUIViewを返す
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView
    }
    
    /// ズーム変更
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        self.updateImageCenter()
    }
    
    /// ズーム完了
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        self.updateImageCenter()
    }
    
    /// ズーム時の矩形を求める
    /// - parameter scale: 拡大率
    /// - parameter center: 中央の座標
    /// - returns: ズーム後の表示エリア
    func zoomRectForScale(scale:CGFloat, center: CGPoint) -> CGRect{
        
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = self.frame.size.height / scale
        zoomRect.size.width = self.frame.size.width / scale
        
        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0
        
        return zoomRect
    }
    
    /// ズーム後の画像の位置を調整する
    func updateImageCenter() {
        
        let image = imageView.image
        
        // UIViewContentMode.ScaleAspectFit時のUIImageViewの画像サイズを求める
        let frame = AVMakeRect(aspectRatio: image!.size, insideRect: imageView.bounds)
        
        var imageSize = CGSize(width: frame.size.width, height: frame.size.height)
        imageSize.width *= scrollView.zoomScale
        imageSize.height *= scrollView.zoomScale
        
        var point: CGPoint = CGPoint.zero
        point.x = imageSize.width / 2
        if imageSize.width < scrollView.bounds.width {
            point.x += (scrollView.bounds.width - imageSize.width) / 2
        }
        point.y = imageSize.height / 2
        if imageSize.height < scrollView.bounds.height {
            point.y += (scrollView.bounds.height - imageSize.height) / 2
        }
        imageView.center = point
    }

}
extension UIScrollView {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
        print("touchesBegan")
    }
}
