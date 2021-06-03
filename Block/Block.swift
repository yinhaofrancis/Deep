//
//  Block.swift
//  Block
//
//  Created by hao yin on 2021/6/3.
//

import Foundation
import CoreText


extension NSAttributedString.Key{
    public static var runDelegate = NSAttributedString.Key(kCTRunDelegateAttributeName as String)
    public static var runBlock = NSAttributedString.Key("RunBlockAttributeName")
}

@resultBuilder
public struct BlockBuild{
    public static func buildBlock(_ components: Block...) -> NSAttributedString {
        return components.reduce(NSMutableAttributedString()) { a, c in
            a.append(c.aStr)
            return a
        }
    }
}

public class Canvas:Block{

    public init(@BlockBuild childs:(Block)->NSAttributedString) {
        super.init(parent: nil, color: CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1,1,1,1])! , width: .zero, height: .zero, childs: childs)
    }
    
}





public struct BFloat{
    public enum Mode{
        case percent
        case origin
        case unset
    }
    public enum Direction{
        case H
        case V
    }
    public var origin:CGFloat
    public var direction:Direction
    public var mode:Mode
    public func value(block:Block?)->CGFloat{
        switch self.mode {
        case .percent:
            switch self.direction {
            case .H:
                return block?.width.value(block: block?.parent) ?? 0 * self.origin
            case .V:
                return block?.height.value(block: block?.parent) ?? 0 * self.origin
            }
        case .origin:
            return origin
        case .unset:
            return 0
        }
    }
    public static var zero:BFloat{
        BFloat(origin: 0, direction: .H, mode: .unset)
    }
    public static func value(v:CGFloat)->BFloat{
        BFloat(origin: v, direction: .H, mode: .origin)
    }
    public static func makeXValue(model:BFloat.Mode = .origin,origin:CGFloat)->BFloat{
        BFloat(origin: origin, direction: .H, mode: model)
    }
    public static func makeYValue(model:BFloat.Mode = .origin,origin:CGFloat)->BFloat{
        BFloat(origin: origin, direction: .H, mode: model)
    }
    
    public static func makeXPercentValue(origin:CGFloat)->BFloat{
        BFloat(origin: origin, direction: .H, mode: .percent)
    }
    public static func makeYPercentValue(origin:CGFloat)->BFloat{
        BFloat(origin: origin, direction: .H, mode: .percent)
    }
}

public typealias buildBlock = (Block)->NSAttributedString
open class Block {
    open var width:BFloat
    open var height:BFloat
    open var baseline:BFloat
    open var color:CGColor?
    open var content:NSAttributedString = NSAttributedString(string: "")
    public var rundelegate:CTRunDelegate?
    public var parent:Block?
    public convenience init(parent:Block?,
                            color:CGColor?,
                            width:CGFloat,
                            height:CGFloat,
                            @BlockBuild childs:(Block)->NSAttributedString) {
        self.init(parent:parent,color:color,width:BFloat.value(v: width),height:BFloat.value(v: height),childs:childs)
    }
    public init(parent:Block?,
                color:CGColor?,
                width:BFloat = .zero,
                height:BFloat = .zero,
                @BlockBuild childs:(Block)->NSAttributedString) {
        self.width = width
        self.height = height
        self.parent = parent
        self.baseline = .zero
        self.color = color
        var c = CTRunDelegateCallbacks(version: 0, dealloc: { _ in
            
        }, getAscent: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.height.value(block: b.parent) - b.baseline.value(block: b)
            
        }, getDescent: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.baseline.value(block: b)
        }, getWidth: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.width.value(block: b.parent)
        })
        self.content = childs(self)
        self.rundelegate = CTRunDelegateCreate(&c, Unmanaged<Block>.passUnretained(self).toOpaque())
    }
    public var aStr: CFAttributedString{

        if let rd = self.rundelegate, let clear = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0,0,0,0]){
            return CFAttributedStringCreate(kCFAllocatorDefault, "1" as CFString, [
                kCTForegroundColorAttributeName:clear,
                kCTFontAttributeName:CTFontCreateUIFontForLanguage(.system, 1, nil) ?? CTFontCreateWithName("TimesNewRomanPSMT" as CFString, 1, nil),
                kCTRunDelegateAttributeName:rd,
                (NSAttributedString.Key.runBlock.rawValue as CFString):self
            ] as CFDictionary)
        }
        return NSAttributedString()
    }
    public func draw(ctx:CGContext,rect:CGRect){
        ctx.saveGState()
        if let fc = self.color{
            ctx.setFillColor(fc)
            ctx.fill(rect)
        }
        let frameset = self.contentFrame
        let frame = CTFramesetterCreateFrame(frameset, CFRangeMake(0,self.content.length), CGPath(rect: rect, transform: nil), nil)
        let rframe = RichTextFrame(frame: frame)
        for u in rframe.lines{
            _ = u.delegateRun
        }
        CTFrameDraw(frame, ctx)
        for u in rframe.lines{
            for i in u.delegateRun{
                let crect = i.rect(line: u)
                i.block?.draw(ctx: ctx, rect: CGRect(x: rect.origin.x + crect.origin.x, y: rect.origin.y + crect.origin.y, width: crect.width, height: crect.height))
            }
        }
        ctx.restoreGState()
    }
    public var contentFrame:CTFramesetter{
        CTFramesetterCreateWithAttributedString(self.content)
    }
}



