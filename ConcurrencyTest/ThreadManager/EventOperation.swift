//
//  CleverOperation.swift
//  ConcurrencyTest
//
//  Created by Yuriy Holovatskyi on 07.05.18.
//  Copyright © 2018 noname. All rights reserved.
//

import UIKit

typealias OperationCompletion = (Bool) -> Void
typealias EventCompletion = (@escaping OperationCompletion) -> Void

protocol EventOperationDelegate: class {
    func eventOperationFinished(wasExecuting: Bool, operation: EventOperation)
}

class EventOperation: Operation {
    
    weak var delegate: EventOperationDelegate?
    var _executing = false {
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
    
    var _finished = false {
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
            if let strongDelegate = delegate {
                strongDelegate.eventOperationFinished(wasExecuting: false, operation: self)
            } else {
                finish(true)
            }
            return
        }
        
        if let name = name {
            print("Started -> \(name)")
        }
        
        executing(true)
        if let block = eventBlock {
            let callback: OperationCompletion = { [weak self] success in
                guard let strongSelf = self else {
                    return
                }
                if let name = strongSelf.name {
                    print("FINISHED -> \(name)")
                }

                if let strongDelegate = strongSelf.delegate {
                    strongDelegate.eventOperationFinished(wasExecuting: true, operation: strongSelf)
                } else {
                    strongSelf.eventBlock = nil
                    strongSelf.executing(false)
                    strongSelf.finish(true)
                }
                
            }
            
            block(callback)
        }
    }
}
