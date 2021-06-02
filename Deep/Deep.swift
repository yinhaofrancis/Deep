//
//  Deep.swift
//  Deep
//
//  Created by hao yin on 2021/6/2.
//

import UIKit
import CoreText

public func make(){
    print("dssds")
}
extension NSAttributedString.Key{
    public static var runDelegate = NSAttributedString.Key(kCTRunDelegateAttributeName as String)
    public static var runBlock = NSAttributedString.Key("RunBlockAttributeName")
}

@resultBuilder
public struct TextBuild{
    public static func buildBlock(_ components: TextComponent...) -> NSAttributedString {
        return components.reduce(NSMutableAttributedString()) { a, c in
            a.append(c.aStr)
            return a
        }
    }
}




public protocol TextComponent{
    var aStr:NSAttributedString { get }
}
extension TextComponent{
    public func wrap(typper:CTTypesetter,len:Int,size:Double)->[CFRange]{
        var index:CFIndex = 0
        var range:[CFRange] = []
        
        while index < len {
            let len = CTTypesetterSuggestClusterBreak(typper, index, size)
            range.append(CFRangeMake(index, len))
            index += len
        }
        return range
    }
    public func makeLine(typper:CTTypesetter,range:CFRange,xOffset:CGFloat,yOffset:CGFloat)->RichTextLine{
        let line = CTTypesetterCreateLine(typper, range)
        return RichTextLine(line: line,yOffset: yOffset,xOffset: xOffset)
    }
    public func generateLines(typper:CTTypesetter,len:Int,limit:CGSize,xOffset:CGFloat,yOffset:CGFloat)->[RichTextLine]{
        let range = self.wrap(typper: typper, len: len, size: Double(limit.width))
        var offset = limit.height
        let lines = range.map { r -> RichTextLine in
            
            var l = self.makeLine(typper: typper, range: r,xOffset:0,yOffset:0)
            let info = l.lineInfo
            offset -= info.ascent
            l.yOffset = offset - yOffset
            l.xOffset = xOffset
            offset -= info.descent
            return l
        }
        return lines
    }
    public func componentSize(lines:[RichTextLine])->CGSize{
        let w = lines.reduce(CGSize.zero) { ww, l in
            let info = l.lineInfo
            return CGSize(width: max(info.width,ww.width), height: ww.height + info.ascent + info.descent)
        }
        return w
    }
    public var typper:CTTypesetter{
        CTTypesetterCreateWithAttributedString(self.aStr as CFAttributedString)
    }
}
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
public protocol Block:TextComponent{
    var callback:CTRunDelegateCallbacks { get }
    var ascent:CGFloat { get }
    var descent:CGFloat { get }
    var width:CGFloat  { get }
}
public struct Space:Block{
    public var callback: CTRunDelegateCallbacks
    
    public var ascent: CGFloat
    
    public var descent: CGFloat
    
    public var width: CGFloat
    
    public var aStr: NSAttributedString{
        let s = UnsafeMutablePointer<Space>.allocate(capacity: 1)
        s.assign(repeating: self, count: 1)
        var c = self.callback
        let rd = CTRunDelegateCreate(&c, s)
        return NSAttributedString(string: "A",attributes: [
            .foregroundColor : UIColor.clear,
            .runDelegate:rd as Any,
            .runBlock:self
        ])
    }
    public init(width:CGFloat){
        self.ascent = 0
        self.descent = 0
        self.width = width
        let c = CTRunDelegateCallbacks(version: 0) { i in
            i.deallocate()
        } getAscent: { i in
            return i.assumingMemoryBound(to: Self.self).pointee.ascent
        } getDescent: { i in
            return i.assumingMemoryBound(to: Self.self).pointee.descent
        } getWidth: { i in
            return i.assumingMemoryBound(to: Self.self).pointee.width
        }
        self.callback = c
    }

}
public struct RichTextLine{
    public var line:CTLine
    public var yOffset:CGFloat
    public var xOffset:CGFloat
    public struct RichTextLineInfo{
        public var ascent:CGFloat
        public var descent:CGFloat
        public var width:CGFloat
        public var leading:CGFloat
    }
    
    public var lineInfo:RichTextLineInfo{
        var info = RichTextLineInfo(ascent: 0, descent: 0, width: 0, leading: 0)
        info.width = CGFloat(CTLineGetTypographicBounds(self.line, &info.ascent, &info.descent, &info.leading))
        return info
    }
    public var delegateRun:[RichTextRun]{
        let runs = (CTLineGetGlyphRuns(line) as! [CTRun]).filter { r in
            let a = CTRunGetAttributes(r) as! [CFString:Any]
            return a[NSAttributedString.Key.runDelegate.rawValue as CFString] != nil
        }
        var runsout:[RichTextRun] = []
        for i in runs {
            let c = CTRunGetGlyphCount(i)
            for j in 0 ..< c {
                let run = RichTextRun(run: i, index: j, len: 1)
                runsout.append(run)
            }
        }
        return runsout
    }
}
public struct RichTextRun:CustomDebugStringConvertible{
    public var debugDescription: String{
        return "x \(xOffset) y \(yOffset) info (\(self.runInfo))"
    }
    
    public struct RichTextRunInfo:CustomDebugStringConvertible{
        public var ascent:CGFloat
        public var descent:CGFloat
        public var width:CGFloat
        public var leading:CGFloat
        public var debugDescription: String{
            return "a \(ascent) d \(descent) w \(width) l \(leading)"
        }
    }
    public var yOffset:CGFloat
    public var xOffset:CGFloat
    public var index:CFIndex
    public var len:CFIndex
    public var run:CTRun
    public var runInfo:RichTextRunInfo{
        var info = RichTextRunInfo(ascent: 0, descent: 0, width: 0, leading: 0)
        info.width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: index, length: len), &info.ascent, &info.descent, &info.leading))
        return info
    }
    public init(run:CTRun,index:CFIndex,len:CFIndex){
        self.run = run
        self.index = index
        self.len = len
        var points = CGPoint.zero
        CTRunGetPositions(run, CFRange(location: index, length: len), &points)
        xOffset = points.x
        yOffset = points.y
    }
    public func rect(line:RichTextLine)->CGRect{
        let runinf = self.runInfo
        return CGRect(x: line.xOffset + self.xOffset, y: line.yOffset - runinf.descent, width: runinf.width, height: runinf.ascent + runinf.descent)
    }
}
public struct RichText:TextComponent{
    public var aStr: NSAttributedString
    
    public init(@TextBuild childs:()->NSAttributedString){
        self.aStr = childs()
    }
}

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
    public func render(component:TextComponent,xOffset:CGFloat = 0,yOffset:CGFloat = 0)->CGImage?{
        self.context.saveGState()
        self.context.clear(CGRect(x: 0, y: 0, width: w, height: h))
    
        let typer = component.typper
        let lines = component.generateLines(typper: typer, len: component.aStr.length, limit: CGSize(width: self.w, height: self.h),xOffset: xOffset,yOffset: yOffset)
        for u in lines {
            self.context.textPosition = CGPoint(x: u.xOffset, y: u.yOffset)
            CTLineDraw(u.line, context)
            for i in u.delegateRun {
                context.setStrokeColor((UIColor.red.cgColor))
                context.stroke(i.rect(line: u))
            }
        }
        self.context.restoreGState()
        return self.context.makeImage()
    }
    public func renderFrame(component:TextComponent)->CGImage?{
        self.context.saveGState()
        self.context.clear(CGRect(x: 0, y: 0, width: w, height: h))
        let frameset = CTFramesetterCreateWithAttributedString(component.aStr)
        let frame = CTFramesetterCreateFrame(frameset, CFRangeMake(0,component.aStr.length), CGPath(rect: CGRect(x: 0, y: 0, width: self.w, height: self.h), transform: nil), nil)
        CTFrameDraw(frame, context)
        self.context.restoreGState()
        return self.context.makeImage()
    }
    public func load(){
        
    }
}
