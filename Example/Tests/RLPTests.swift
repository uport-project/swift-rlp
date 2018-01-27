//
//  TestRLP.swift
//  RLP_Tests
//
//  Created by josh on 1/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

class RLPTests: QuickSpec {
    
    override func spec() {
        describe("these will fail") {
            
            it("can do maths") {
                expect(1) == 2
            }
            
            it("can read") {
                expect("number") == "string"
            }
            
            it("will eventually fail") {
                expect("time").toEventually( equal("done") )
            }
            
            context("these will pass") {
                
                it("can do maths") {
                    expect(23) == 23
                }
                
                it("can read") {
                    expect("🐮") == "🐮"
                }
                
                it("will eventually pass") {
                    var time = "passing"
                    
                    DispatchQueue.main.async {
                        time = "done"
                    }
                    
                    waitUntil { done in
                        Thread.sleep(forTimeInterval: 0.5)
                        expect(time) == "done"
                        
                        done()
                    }
                }
            }
        }
    }
    
}
