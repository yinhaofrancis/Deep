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
        super.init(parent: nil, color: CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1,1,1,1])! , width: .unset(direction: .H), height: .unset(direction: .V),direction: .H, childs: childs)
    }
}

public enum Align{
    case start
    case end
    case center
    case stretch
}
public enum Content{
    case start
    case center
    case end
    case between
    case around
    case evenly
}

public enum Direction{
    case H
    case V
}


public struct BFloat{
    public enum Mode{
        case percent
        case origin
        case unset
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
    public static func unset(direction:Direction)->BFloat{
        BFloat(origin: 0, direction:direction, mode: .unset)
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
    open var ascent:CGFloat{
        guard let p = parent else { return 0 }
        return self.baseline.value(block: p)
    }
    open var descent:CGFloat{
        guard let p = parent else { return 0 }
        
        if p.direction == .H{
            if self.height.mode == .unset{
                return self.contentSize.height
            }else{
                return self.height.value(block: p) - self.baseline.value(block: p)
            }
            
        }else{
            if self.width.mode == .unset{
                return self.contentSize.width
            }else{
                return self.width.value(block: p) - self.baseline.value(block: p)
            }
        }
    }
    open var size:CGFloat{
        guard let p = parent else { return 0 }
        if p.direction == .V{
            if self.height.mode == .unset{
                return self.contentSize.height
            }else{
                return self.height.value(block: p)
            }
            
        }else{
            if self.height.mode == .unset{
                return self.contentSize.width
            }else{
                return self.width.value(block: p)
            }
        }
    }
    open var width:BFloat
    open var height:BFloat
    open var baseline:BFloat
    open var color:CGColor?
    open var content:NSAttributedString = NSAttributedString(string: "")
    public var rundelegate:CTRunDelegate?
    public var parent:Block?
    public var direction:Direction = .H
    public var justcontent:Content
    public var alignItem:Align
    public var alignContent:Content
    public var alignSelf:Align
    public convenience init(parent:Block?,
                            color:CGColor? = nil,
                            width:CGFloat,
                            height:CGFloat,
                            direction:Direction = .H,
                            justcontent:Content = .start,
                            alignItem:Align = .stretch,
                            alignContent:Content = .start,
                            alignSelf:Align = .stretch,
                            @BlockBuild childs:(Block)->NSAttributedString) {
        self.init(parent:parent,
                  color:color,
                  width:BFloat.value(v: width),
                  height:BFloat.value(v: height),
                  direction: direction,
                  justcontent:justcontent,
                  alignItem:alignItem,
                  alignContent:alignContent,
                  alignSelf:alignSelf,
                  childs:childs)
    }
    public init(parent:Block?,
                color:CGColor? = nil,
                width:BFloat = .unset(direction: .H),
                height:BFloat = .unset(direction: .V),
                direction:Direction = .H,
                justcontent:Content = .start,
                alignItem:Align = .stretch,
                alignContent:Content = .start,
                alignSelf:Align = .stretch,
                @BlockBuild childs:(Block)->NSAttributedString) {
        self.width = width
        self.height = height
        self.parent = parent
        self.baseline = .makeXValue(origin: 0)
        self.color = color
        var c = CTRunDelegateCallbacks(version: 0, dealloc: { _ in
            
        }, getAscent: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.ascent
            
        }, getDescent: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.descent
        }, getWidth: { i in
            let b = Unmanaged<Block>.fromOpaque(i).takeUnretainedValue()
            return b.size
        })
        self.justcontent = justcontent
        self.alignItem = alignItem
        self.alignContent = alignContent
        self.alignSelf = alignSelf
        self.content = childs(self)
        self.rundelegate = CTRunDelegateCreate(&c, Unmanaged<Block>.passUnretained(self).toOpaque())
    }
    public var aStr: CFAttributedString{
        let size = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        size.pointee = 0
        let maxspaceing = CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: size)
        let mimspaceing = CTParagraphStyleSetting(spec: .minimumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: size)
        let lineajSize = CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<CGFloat>.size, value: size)
        let parasize = CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: size)
        let param = CTParagraphStyleSetting(spec: .paragraphSpacingBefore, valueSize: MemoryLayout<CGFloat>.size, value: size)
        let p = CTParagraphStyleCreate([maxspaceing,mimspaceing,lineajSize,parasize,param], 5)
        if let rd = self.rundelegate, let clear = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0,0,0,0]){
            let atr = CFAttributedStringCreate(kCFAllocatorDefault, "1" as CFString, [
                kCTForegroundColorAttributeName:clear,
                kCTFontAttributeName:CTFontCreateUIFontForLanguage(.system, 0.001, nil) ?? CTFontCreateWithName("TimesNewRomanPSMT" as CFString, 0.001, nil),
                kCTRunDelegateAttributeName:rd,
                (NSAttributedString.Key.runBlock.rawValue as CFString):self,
                kCTParagraphStyleAttributeName:p
            ] as CFDictionary)
            size.deallocate()
            return atr ?? NSAttributedString() as CFAttributedString
        }
        return NSAttributedString()
    }
    public func draw(ctx:CGContext,rect:CGRect){
        ctx.saveGState()
        if let fc = self.color{
            ctx.setFillColor(fc)
            ctx.fill(rect)
        }else{
            ctx.setStrokeColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1,0,0,1])!)
            ctx.stroke(rect)
        }
        
        let frameset = self.contentFrame
        let frame = CTFramesetterCreateFrame(frameset, CFRangeMake(0,self.content.length), CGPath(rect: rect , transform: nil), [kCTFrameProgressionAttributeName:self.direction == .H ? CTFrameProgression.topToBottom.rawValue: CTFrameProgression.leftToRight.rawValue] as CFDictionary)
        let rframe = RichTextFrame(frame: frame, direction: self.direction)
        for u in rframe.lines{
            for i in u.delegateRun{
                let crect = i.rect(line: u)
                i.block?.draw(ctx: ctx, rect: CGRect(x: rect.origin.x + crect.origin.x, y: rect.origin.y + crect.origin.y, width: crect.width, height: crect.height))

            }
        }
        ctx.restoreGState()
    }
    public var contentFrame:CTFramesetter{
        let a = NSMutableAttributedString(attributedString: self.content)
        
        a.addAttribute(.verticalGlyphForm, value: self.direction == .H ? 0 : 1, range: NSMakeRange(0, a.length))
        return CTFramesetterCreateWithAttributedString(a)
    }
    public var contentSize:CGSize{
        let w:CGFloat = self.width.mode == .unset ? .infinity : self.width.value(block: self.parent)
        let h:CGFloat = self.height.mode == .unset ? .infinity : self.height.value(block: self.parent)
        return CTFramesetterSuggestFrameSizeWithConstraints(self.contentFrame, CFRangeMake(0, self.content.length), nil, CGSize(width: w, height: h), nil)
    }
}



