//
//  Deep.swift
//  Deep
//
//  Created by hao yin on 2021/6/2.
//

import UIKit
import CoreText

public class Container:Space{
    public init(@BlockBuild childs:()->NSAttributedString){
        self._aStr = childs()
    }
    public var _aStr: NSAttributedString
    public override var aStr: NSAttributedString{
        return _aStr
    }
}
public struct RichText:Block{
    public var callback: CTRunDelegateCallbacks
    
    public var ascent: CGFloat
    
    public var descent: CGFloat
    
    public var width: CGFloat
    
    public var isFlex: Bool = false
    
    public var extraSize: CGFloat = 0
    
    public func draw(ctx: CGContext, frame: CGRect) {
        ctx.saveGState()
   
        let frameset = CTFramesetterCreateWithAttributedString(self.aStr)
        let frame = CTFramesetterCreateFrame(frameset, CFRangeMake(0,self.aStr.length), CGPath(rect:frame, transform: nil), nil)
        let rframe = RichTextFrame(frame: frame)
        for u in rframe.lines{
            _ = u.delegateRun
        }
        CTFrameDraw(frame, ctx)
        
        for u in rframe.lines{
            for i in u.delegateRun{
                let rect = i.rect(line: u)
                i.block?.draw(ctx: ctx, frame: rect)
            }
        }
        ctx.restoreGState()
    }
    
    public var aStr: NSAttributedString
    
    public init(width:CGFloat,ascent:CGFloat = 0,descent:CGFloat = 0,@TextBuild childs:()->NSAttributedString){
        let a = NSMutableAttributedString(attributedString: childs())
        self.aStr = a;
        self.width = width
        self.ascent = ascent
        self.descent = descent
        let c = CTRunDelegateCallbacks(version: 0) { i in
       
        } getAscent: { i in
            
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().ascent
        } getDescent: { i in
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().descent
        } getWidth: { i in
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().width + Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().extraSize
        }
        self.callback = c
    }
}

public class Space:Block{
    public var isFlex: Bool
    
    public func draw(ctx: CGContext, frame: CGRect) {
        self.drawRect = frame
        ctx.saveGState()
        if(!self.isFlex){
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fillEllipse(in: frame.inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)))
        }
        if let img = image{
            ctx.draw(img, in: frame)
        }
        ctx.restoreGState()
    }
    
    public var callback: CTRunDelegateCallbacks
    
    public var ascent: CGFloat
    
    public var descent: CGFloat
    
    public var width: CGFloat
    
    public var image:CGImage?
    public var drawRect:CGRect?
    public var extraSize:CGFloat = 0
    
    public var aStr: NSAttributedString{
        var c = self.callback
        let rd = CTRunDelegateCreate(&c, Unmanaged<Space>.passUnretained(self).toOpaque())
        return NSAttributedString(string: "1",attributes: [
            .foregroundColor : UIColor.clear,
            .runDelegate:rd as Any,
            .runBlock:self
        ])
    }
    public convenience init(fontSize:CGFloat){
        let ctfont = CTFontCreateUIFontForLanguage(.system, fontSize, nil) ?? CTFontCreateWithName("TimesNewRomanPSMT" as CFString, fontSize, nil)
        self.init(width:CTFontGetSize(ctfont),ascent:CTFontGetAscent(ctfont),descent:CTFontGetDescent(ctfont))
        self.isFlex = false
    }
    public init(width:CGFloat = 0,ascent:CGFloat = 0,descent:CGFloat = 0){
        self.ascent = ascent
        self.descent = descent
        self.width = width
        let c = CTRunDelegateCallbacks(version: 0) { i in
       
        } getAscent: { i in
            
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().ascent
        } getDescent: { i in
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().descent
        } getWidth: { i in
            return Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().width + Unmanaged<Space>.fromOpaque(i).takeUnretainedValue().extraSize
        }
        self.callback = c
        self.isFlex = true
    }

}

