//
//  CoreTextExt.swift
//  Block
//
//  Created by hao yin on 2021/6/3.
//

import Foundation
import CoreText
public struct RichTextLine{
    public var line:CTLine
    public var yOffset:CGFloat
    public var xOffset:CGFloat
    public var limit:CGSize
    public var direction:Direction
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
                var run = RichTextRun(run: i, index: j, len: 1)
                let dir = (CTRunGetAttributes(run.run) as! [String:Any])
                run.block = (dir[NSAttributedString.Key.runBlock.rawValue] as! Block)
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
        if line.direction == .H{
            return CGRect(x: line.xOffset + self.xOffset, y: line.yOffset + self.yOffset, width: runinf.width, height: runinf.ascent + runinf.descent)
        }else{
            return CGRect(x: line.xOffset + self.xOffset, y: line.yOffset + self.yOffset - runinf.width , width: runinf.ascent + runinf.descent , height: runinf.width)
        }
        
    }
    public var block:Block?
}

public struct RichTextFrame{
    public var frame:CTFrame
    public var direction:Direction
    public init(frame:CTFrame,direction:Direction){
        self.frame = frame
        self.direction = direction
    }
    public var lines:[RichTextLine]{
    
        let lines = CTFrameGetLines(self.frame) as! [CTLine]
        let p = UnsafeMutablePointer<CGPoint>.allocate(capacity: lines.count)
        
        CTFrameGetLineOrigins(self.frame, CFRangeMake(0, lines.count), p)
        var result:[RichTextLine] = []
        for i in 0 ..< lines.count{
            
            let y = p.advanced(by: i).pointee.y
            let x = p.advanced(by: i).pointee.x
            var l = RichTextLine(line: lines[i], yOffset: y, xOffset: x,limit: CTFrameGetPath(self.frame).boundingBoxOfPath.size, direction: self.direction)
            if self.direction == .H{
                l.yOffset -= l.lineInfo.descent
            }else{
                l.xOffset -= l.lineInfo.descent
            }
            
            result.append(l)
        }
        p.deallocate()
        return result
    }
}
