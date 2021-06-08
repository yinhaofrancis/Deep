//
//  exampleTests.swift
//  exampleTests
//
//  Created by hao yin on 2021/6/8.
//

import XCTest
@testable import Block
class exampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let u = Cache.shared.cacheDictionary?.appendingPathComponent("ko")
        let s = CacheStorage<CacheDataModel<StringSwap>>(localStorage: u!)
        s.delete()
        s.setHeader(size: 100, remoteUrl: URL(string: "https://www.qq.com")!, success: true)
        try s.writeHeader()
        let ss = CacheStorage<CacheDataModel<StringSwap>>(localStorage: u!)
        try ss.readHeader()
        XCTAssert(ss.header?.size == 100, "size fail")
        XCTAssert(ss.header?.remoteUrl == URL(string: "https://www.qq.com")!, "remote url fail")
        XCTAssert(ss.header?.success == true, " status fail ")
        try ss.appendData(data: "dadasdad".data(using: .utf8)!)
        print(ss.originModel)
        XCTAssert(ss.originModel == "dadasdad", "fail")
    }
    

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
