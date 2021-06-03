//
//  Text.swift
//  Deep
//
//  Created by hao yin on 2021/6/3.
//

import Foundation






public struct TextSpan:TextComponent{
    public var aStr: NSAttributedString{
        NSAttributedString(string: text, attributes: attribute)
    }
    
    public var text:String
    public var attribute:[NSAttributedString.Key:Any]
    
    public init(text:String,attribute:[NSAttributedString.Key:Any]){
        self.text = text
        self.attribute = attribute
    }
}
