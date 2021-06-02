//
//  ViewController.swift
//  example
//
//  Created by hao yin on 2021/6/2.
//

import UIKit
import Deep
class ViewController: UIViewController {

    @IBOutlet weak var text2: UIImageView!
    @IBOutlet weak var label: UIImageView!
    var tc:TextContext = try! TextContext(w: 100, h: 200)
    override func viewDidLoad() {
        super.viewDidLoad()
        let a = RichText {
            TextSpan(text: "a", attribute: [.font:UIFont.systemFont(ofSize: 15)])
            Space(width: 5)
            TextSpan(text: "eeeeeeeeeerrrrrryyeeee", attribute: [.font:UIFont.systemFont(ofSize: 8)])
            Space(width: 5)
            TextSpan(text: "qqqq", attribute: [.font:UIFont.systemFont(ofSize: 13)])
        }
        label.image = UIImage(cgImage: tc.render(component: a)!,scale: UIScreen.main.scale, orientation: .up)
        text2.image = UIImage(cgImage: tc.renderFrame(component: a)!, scale: UIScreen.main.scale, orientation: .up)
    }


}


