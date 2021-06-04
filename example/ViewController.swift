//
//  ViewController.swift
//  example
//
//  Created by hao yin on 2021/6/2.
//

import UIKit
import Block
class ViewController: UIViewController {

   
    @IBOutlet weak var text2: UIImageView!
    @IBOutlet weak var label: UIImageView!
    var direction:Direction = .H
    var tc:TextContext = try! TextContext(w: 100, h: 200)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.draw(w: 200);
    }


    @IBAction func draw(slider:UISlider){
        self.draw(w: CGFloat(slider.value))
    }
    func draw(w:CGFloat){
        tc = try! TextContext(w: Int(w), h: Int(w))
        let c = Canvas {
            
            Block(width: 10, height: 20) { }
            Block(width: 20, height: 30) {}
            Block(width: 30, height: 40) {  }
            Block(width: 40, height: 50,flex: 1) {  }
            Block(height: 20, flex:1) {  }
            Block(height: 10, flex:2) {  }
            Block(justcontent: .center, alignSelf: .stretch) {
                Block(color: UIColor.blue.cgColor, width: 10, height: 10) {  }
                Block(color: UIColor.blue.cgColor, width: 20, height: 20) {  }
                Block(color: UIColor.blue.cgColor, width: 30, height: 30) {  }
            }
        }
        c.direction = self.direction
        c.alignItem = .center
        c.justcontent = .evenly
        label.image = UIImage(cgImage: tc.render(component: c)! ,scale: UIScreen.main.scale, orientation: .up)
        
//        let a = RichText(width: 100) {
//            TextSpan(text: "aaaaaaaaa", attribute: [.font:UIFont.systemFont(ofSize: 15)])
//            Space()
//            TextSpan(text: "得到的", attribute: [.font:UIFont.systemFont(ofSize: 15)])
//            Space()
//            TextSpan(text: "eeeeeeeeeerrrrrryyeeee", attribute: [.font:UIFont.systemFont(ofSize: 8)])
//            Space(fontSize: 20)
//            
//            TextSpan(text: "qqqq", attribute: [.font:UIFont.systemFont(ofSize: 13)])
//        }
//        let c = Container {
//            Container {
//                a
//            }
//            a
//            Container {
//                a
//            }
//        }
//        print(c.aStr)
//        label.image = UIImage(cgImage: tc.render(component: c)!,scale: UIScreen.main.scale, orientation: .up)

////        text2.image = UIImage(cgImage: tc.renderFrame(component: a)!, scale: UIScreen.main.scale, orientation: .up)
//        
    }
    @IBAction func chage(_ sender: UISwitch) {

        self.direction = sender.isOn ? .H : .V
        self.draw(w: 200)
    }
}


