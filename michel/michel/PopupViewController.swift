import UIKit

class PopupViewController: UIViewController {

    var outputImage = UIImage()
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var labelCapture: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let screenWidth:CGFloat = view.frame.size.width
        let screenHeight:CGFloat = view.frame.size.height
        
        // UIImageView 初期化
        let imageView = UIImageView(image: outputImage)
        imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        self.view.addSubview(imageView)
        
        self.view.addSubview(labelCapture)
        self.view.addSubview(saveButton)
        
        }
    
    @IBAction func tapSaveButton(_ sender: Any) {
        // 画像をカメラロールに保存す
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
    }
}
