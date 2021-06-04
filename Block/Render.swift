//
//  Render.swift
//  Block
//
//  Created by hao yin on 2021/6/3.
//

import Foundation
import UIKit
import CoreText
public class TextContext{
    public var context:CGContext
    public var w:Int
    public var h:Int
    public init(w:Int,h:Int) throws {
        let scale = UIScreen.main.scale
        guard let ctx = CGContext(data: nil,
                                  width: w * Int(scale),
                                  height: h * Int(scale),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 4 * w * Int(scale),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "error", code: 0, userInfo: nil)
        }
        ctx.scaleBy(x: scale, y: scale)
        self.context = ctx
        self.w = w
        self.h = h
    }
    public func render(component:Canvas)->CGImage?{
        self.context.saveGState()
        self.context.clear(CGRect(x: 0, y: 0, width: w, height: h))
        component.draw(ctx: self.context, rect: CGRect(x: 0, y: 0, width: w, height: h))
        self.context.restoreGState()
        return self.context.makeImage()
    }
    public func load(){
        
    }
}
