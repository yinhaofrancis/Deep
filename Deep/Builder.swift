//
//  Builder.swift
//  Deep
//
//  Created by hao yin on 2021/6/3.
//

import UIKit
import CoreText

public protocol TextComponent{
    var aStr:NSAttributedString { get }
}

extension TextComponent{
    public func preprocess(rect:CGRect){
        let typer = self.typper
        let lines = self.generateLines(typper: typer, len: self.aStr.length, limit: CGSize(width: rect.width, height: rect.height),xOffset: rect.minX,yOffset: rect.minY)
        for i in lines {
            i.fillSpace()
        }
    }
    public func wrap(typper:CTTypesetter,len:Int,size:Double)->[CFRange]{
        var index:CFIndex = 0
        var range:[CFRange] = []
        
        while index < len {
            let len = CTTypesetterSuggestLineBreak(typper, index, size)
            range.append(CFRangeMake(index, len))
            index += len
        }
        return range
    }
    public func makeLine(typper:CTTypesetter,range:CFRange,xOffset:CGFloat,yOffset:CGFloat,limit:CGSize)->RichTextLine{
        let line = CTTypesetterCreateLine(typper, range)
        return RichTextLine(line: line,yOffset: yOffset,xOffset: xOffset,limit: limit)
    }
    public func generateLines(typper:CTTypesetter,len:Int,limit:CGSize,xOffset:CGFloat,yOffset:CGFloat)->[RichTextLine]{
        let range = self.wrap(typper: typper, len: len, size: Double(limit.width))
        var offset = limit.height
        let lines = range.map { r -> RichTextLine in
            
            var l = self.makeLine(typper: typper, range: r,xOffset:0,yOffset:0,limit: limit)
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


public protocol Block:TextComponent{
    var callback:CTRunDelegateCallbacks { get }
    var ascent:CGFloat { get }
    var descent:CGFloat { get }
    var width:CGFloat  { get }
    var isFlex:Bool { get }
    var extraSize:CGFloat { get set }
    func draw(ctx:CGContext,frame:CGRect)
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
@resultBuilder
public struct BlockBuild{
    public static func buildBlock(_ components: Block...) -> NSAttributedString {
        return components.reduce(NSMutableAttributedString()) { a, c in
            a.append(c.aStr)
            return a
        }
    }
}
