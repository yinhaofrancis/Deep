//
//  Bean.swift
//  Bean
//
//  Created by hao yin on 2021/6/9.
//

import Foundation

public class WeakBean<T:AnyObject>:Hashable{
    public static func == (lhs: WeakBean, rhs: WeakBean) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        let p = UnsafeRawBufferPointer(start: Unmanaged<WeakBean<T>>.passUnretained(self).toOpaque(), count: MemoryLayout<WeakBean<T>>.size)
        hasher.combine(bytes: p)
    }
    
    weak var bean:T?
}
public class Shoots{
    private var lock:UnsafeMutablePointer<pthread_mutex_t> = UnsafeMutablePointer.allocate(capacity: 1)
    public static var shared:Shoots = Shoots()
    public func query<T>(name:String,type:T.Type)->Pods<T>{
        pthread_mutex_lock(self.lock)
        let name = "\(type)"
        var pod = self.dictionary[name] as? Pods<T>
        if(pod == nil){
            pod = Pods<T>()
            self.dictionary[name] = pod
        }
        pthread_mutex_unlock(self.lock)
        return pod!
    }
    init() {
        pthread_mutex_init(self.lock, nil)
    }
    deinit {
        pthread_mutex_destroy(self.lock)
    }
    public var dictionary:[String:Any] = [:]
}
public class Pods<T>{
    private var lock:UnsafeMutablePointer<pthread_mutex_t> = UnsafeMutablePointer.allocate(capacity: 1)
    public var content:T?{
        didSet{
            for i in beans {
                guard let ob = i.bean?.observer else { continue }
                ob.callback(oldValue,content)
            }
            pthread_mutex_lock(self.lock)
            self.beans = self.beans.filter { i in
                i.bean != nil
            }
            pthread_mutex_unlock(self.lock)
        }
    }
    public var beans:Set<WeakBean<Bean<T>>> = Set()
    public init() {
        pthread_mutex_init(self.lock, nil)
    }
    deinit {
        pthread_mutex_destroy(self.lock)
    }
}
public struct BeanObserver<T>{

    public var callback:(_ from:T?,_ to:T?)->Void
}


@propertyWrapper
public class Bean<T>:Hashable{
    public static func == (lhs: Bean<T>, rhs: Bean<T>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        let p = UnsafeRawBufferPointer(start: Unmanaged<Bean<T>>.passUnretained(self).toOpaque(), count: MemoryLayout<Bean<T>>.size)
        hasher.combine(bytes: p)
    }
    public private(set) var name:String
    public var wrappedValue:T? {
        get{
            return pods.content
        }
    }
    public func setState(state:T?){
        self.pods.content = state
    }
    public var pods:Pods<T>
    public var observer:BeanObserver<T>?
    public init(name:String) {
        self.name = name
        self.pods = Shoots.shared.query(name: self.name, type: T.self)
        let wb = WeakBean<Bean<T>>()
        wb.bean = self
        self.pods.beans.insert(wb)
        guard let state = wrappedValue else { return }
        self.setState(state: state)
    }
    public var projectedValue:Bean<T>{
        return self
    }
}
