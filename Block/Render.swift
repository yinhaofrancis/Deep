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
//    public func render(component:Block,frame:CGRect? = nil)->CGImage?{
//        self.context.saveGState()
//        self.context.clear(CGRect(x: 0, y: 0, width: w, height: h))
//
//        let rect = frame ?? CGRect(x: 0, y: 0, width: w, height: h)
//        component.preprocess(rect: rect)
//        let typer = component.typper
//        let lines = component.generateLines(typper: typer, len: component.aStr.length, limit: CGSize(width: rect.width, height: rect.height),xOffset: rect.minX,yOffset: rect.minY)
//
//        for u in lines {
//            self.context.textPosition = CGPoint(x: u.xOffset, y: u.yOffset)
//            let _ = u.delegateRun;
//            CTLineDraw(u.line, context)
//            for i in u.delegateRun {
//                let rect = i.rect(line: u)
//                i.block?.draw(ctx: context, frame: rect)
//            }
//        }
//        self.context.restoreGState()
//        return self.context.makeImage()
//    }
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
