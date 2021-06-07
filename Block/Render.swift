//
//  Render.swift
//  Block
//
//  Created by hao yin on 2021/6/3.
//

import Foundation
import QuartzCore
import CoreText
import ImageIO


import MobileCoreServices
import CoreServices

public class TextContext{
    public var context:CGContext
    public var w:Int
    public var h:Int
    public init(w:Int,h:Int,scale:CGFloat) throws {
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
        guard let image = self.context.makeImage() else { return nil }
        guard let png = self.toPngImage(image: image) else { return image }
        return png
    }
    public func toPngImage(image:CGImage)->CGImage?{
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        guard let detination = CGImageDestinationCreateWithData(data ,kUTTypePNG, 1, nil) else { return nil }
        CGImageDestinationAddImage(detination, image, nil)
        CGImageDestinationFinalize(detination)
        guard let source = CGImageSourceCreateWithData(data, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
