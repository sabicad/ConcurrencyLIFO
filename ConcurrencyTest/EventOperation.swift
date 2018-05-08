//
//  CleverOperation.swift
//  ConcurrencyTest
//
//  Created by Yuriy Holovatskyi on 07.05.18.
//  Copyright © 2018 noname. All rights reserved.
//

import UIKit

typealias OperationCompletion = (Bool) -> Void
typealias EventCompletion = (OperationCompletion) -> Void

class EventOperation: Operation {
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func executing(_ executing: Bool) {
        _executing = executing
    }
    
    func finish(_ finished: Bool) {
        _finished = finished
    }
    
    var eventBlock: EventCompletion? = nil
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        if let block = eventBlock {
            let callback: OperationCompletion = { success in
                self.executing(false)
                self.finish(true)
            }
            
            block(callback)
        }
    }
}
