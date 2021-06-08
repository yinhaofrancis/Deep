//
//  Cache.swift
//  Block
//
//  Created by hao yin on 2021/6/8.
//

import Foundation
import UIKit


public class Cache{
    public static var shared:Cache = {Cache(identify: "com.wy.cache")}()
    public let identify:String
    public init(identify:String){
        self.identify = identify
    }
    public var systemCacheDictionary:URL?{
        try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    public var cacheDictionary:URL?{
        guard let url = self.systemCacheDictionary?.appendingPathComponent(self.identify) else { return nil }
        var b:ObjCBool = ObjCBool(false)
        let a = !FileManager.default.fileExists(atPath: url.absoluteString, isDirectory: &b)
        if !a || (a && !b.boolValue){
            do{
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }catch{
                return nil
            }
            
        }
        return url
    }
}

public protocol CacheModel{
    associatedtype OriginType
    func appendData(data:Data)
    var object:OriginType { get }
    init()
}
public protocol ModelSwap{
    associatedtype Target
    static func swap(data:Data)->Target
}

public class DataSwap:ModelSwap{
    public typealias Target = Data
    public static func swap(data: Data) -> Data {
        return data
    }
}
public class StringSwap:ModelSwap{
    public static func swap(data: Data) -> String {
        String(data: data, encoding: .utf8) ?? ""
    }
    
    public typealias Target = String
    
    
}

public class CacheDataModel<Swap:ModelSwap>:CacheModel{
    public typealias OriginType = Swap.Target
    
    public required init() {
        self.baseData = Data()
    }
    
    public func appendData(data: Data) {
        self.baseData.append(data)
    }
    
    public var baseData: Data
    
    public var object: OriginType{
        Swap.swap(data: self.baseData)
    }
    
}




public class CacheStorage<Type:CacheModel>{
    public struct CacheStorageHeader:Codable{
        public var size:UInt
        public var remoteUrl:URL
        public var success:Bool
    }
    public private(set) var header:CacheStorageHeader?
    public private(set) var model:Type?
    public var originModel:Type.OriginType?{
        self.model?.object
    }
    public var dataIndex:UInt64 = 0
    public var localFilePath:URL
    public var rwlock:UnsafeMutablePointer<pthread_rwlock_t> = .allocate(capacity: 1)
    public var read:FileHandle?{
        self.checkFile(path: self.localFilePath)
        return try? FileHandle(forReadingFrom: self.localFilePath)
    }
    public var write:FileHandle?{
        self.checkFile(path: self.localFilePath)
        return try? FileHandle(forWritingTo: self.localFilePath)
    }
    public init(localStorage:URL){
        self.localFilePath = localStorage
        pthread_rwlock_init(self.rwlock, nil)
        do {
            try self.readHeader()
            try self.loadData()
        } catch {
            
        }
        
    }
    public func checkFile(path:URL){
        if !FileManager.default.fileExists(atPath: self.localFilePath.path){
            FileManager.default.createFile(atPath: self.localFilePath.path, contents: nil, attributes: nil)
        }
    }
    public func readHeader() throws{
        try self.readPerform { read in
            self.checkFile(path: self.localFilePath)
            guard let read = self.read else { throw NSError(domain: "no file handle", code: 0, userInfo: nil) }
            if #available(iOSApplicationExtension 13.0, *) {
                try read.seek(toOffset: 0)
            } else {
                read.seek(toFileOffset: 0)
            }
            let data = read.readData(ofLength: MemoryLayout<Int>.size)
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let pointerBuffer = UnsafeMutableBufferPointer<Int>.init(start: pointer, count: 1)
            _ = data.copyBytes(to: pointerBuffer)
            let len = pointer.pointee.byteSwapped
            let headData = read.readData(ofLength: len)
            self.header = try JSONDecoder().decode(CacheStorageHeader.self, from: headData)
            self.dataIndex = UInt64(data.count + headData.count)
            pointer.deallocate()
            if #available(iOSApplicationExtension 13.0, *) {
                try read.close()
            } else {
                read.closeFile()
            }
        }
       
    }
    public func setHeader(size:UInt,remoteUrl:URL,success:Bool){
        self.header = CacheStorageHeader(size: size, remoteUrl: remoteUrl, success: success)
    }
    public func writeHeader() throws {
        try self.writePerform { write in
            self.checkFile(path: self.localFilePath)
            guard let write = self.write else { throw NSError(domain: "no file handle", code: 0, userInfo: nil) }
            if #available(iOSApplicationExtension 13.0, *) {
                try write.seek(toOffset: 0)
            } else {
                write.seek(toFileOffset: 0)
            }
            
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            guard let currentHeader = self.header else {
                throw NSError(domain: "no header to write", code: 0, userInfo: nil)
            }
            let data = try JSONEncoder().encode(currentHeader)
            pointer.pointee = data.count.byteSwapped
            let temp:Data = Data(bytes: pointer, count: MemoryLayout<Int>.size)
            write.write(temp)
            write.write(data)
            self.dataIndex = UInt64(temp.count + data.count)
            pointer.deallocate()
            if #available(iOSApplicationExtension 13.0, *) {
                try write.close()
            } else {
                write.closeFile()
            }
        }
    }
    public func readPerform(call:(FileHandle) throws ->Void) throws{
        pthread_rwlock_rdlock(self.rwlock)
        defer {
            pthread_rwlock_unlock(self.rwlock)
        }
        guard let read = self.read else { throw NSError(domain: "no file handle", code: 0, userInfo: nil) }
        try call(read)
    }
    public func writePerform(call:(FileHandle) throws ->Void) throws{
        pthread_rwlock_wrlock(self.rwlock)
        defer {
            pthread_rwlock_unlock(self.rwlock)
        }
        guard let write = self.write else { throw NSError(domain: "no file handle", code: 0, userInfo: nil) }
        try call(write)
    }
    public func delete(){
        pthread_rwlock_wrlock(self.rwlock)
        try? FileManager.default.removeItem(at: self.localFilePath)
        pthread_rwlock_unlock(self.rwlock)
    }
    public func appendData(data:Data) throws {
        try self.writePerform { w in
            if self.model == nil{
                try self.loadData()
            }
            self.model?.appendData(data: data)
            if #available(iOSApplicationExtension 13.4, *) {
                try w.seekToEnd()
            } else {
                w.seekToEndOfFile()
            }
            w.write(data)
        }
    }
    public func loadData() throws {
        try self.readPerform(call: { w in
            if #available(iOSApplicationExtension 13.0, *) {
                try w.seek(toOffset: self.dataIndex)
            } else {
                w.seek(toFileOffset: self.dataIndex)
            }
            self.model = Type()
            if #available(iOSApplicationExtension 13.4, *) {
                
                self.model?.appendData(data: try w.readToEnd() ?? Data())
            } else {
                self.model?.appendData(data: w.readDataToEndOfFile())
            }
        })
    }
    deinit {
        pthread_rwlock_destroy(self.rwlock)
        self.rwlock.deallocate()
    }
}
