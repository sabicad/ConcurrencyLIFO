//
//  ThreadsManager.swift
//  ConcurrencyTest
//
//  Created by Yuriy Holovatskyi on 25.11.2020.
//  Copyright © 2020 noname. All rights reserved.
//

import UIKit

enum ThreadCase: Int {
    case main = 0
    case background = 1
    case last = 2
}

class ThreadsManager: NSObject {
    
    fileprivate var wasRequest: Bool = false
    fileprivate var eventsQueue = OperationQueue()
    fileprivate var uiRequests: [EventCompletion] = []
    fileprivate var uiNames: [String] = []
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        initQueue()
    }
    
}

// MARK: - Public

extension ThreadsManager {
    func addOperation(thread: ThreadCase, name: String, block: @escaping EventCompletion) {
        if thread == .main {
            addUIOperation(block, name: name)
        } else {
            addBackgroundOperation(block, name: name)
        }
    }
}

// MARK: - Private

fileprivate extension ThreadsManager {
    func addBackgroundOperation(_ block: @escaping EventCompletion, name: String) {
        let operation = EventOperation()
        operation.delegate = self
        operation.eventBlock = block
        operation.name = name
        
        eventsQueue.addOperation(operation)
    }
    
    func addUIOperation(_ block: @escaping EventCompletion, name: String) {
        if eventsQueue.operations.count > 0 {
            uiRequests.append(block)
            uiNames.append(name)
            wasRequest = true
        } else {
            let operation = EventOperation()
            operation.delegate = self
            operation.eventBlock = block
            operation.name = name
            eventsQueue.addOperation(operation)
        }
    }
    
    func addToHeadOperations(operations: [EventOperation], queueToAdd: OperationQueue) -> OperationQueue {
        wasRequest = false
        
        let newQueue = OperationQueue()
        newQueue.isSuspended = true
        newQueue.maxConcurrentOperationCount = 1
        operations.forEach {
            newQueue.addOperation($0)
        }
        
        let oldQueueOperations = queueToAdd.operations as! [EventOperation]
                
        oldQueueOperations.forEach{
            let operation = EventOperation()
            operation.delegate = self
            operation.eventBlock = $0.eventBlock
            operation.name = $0.name
            newQueue.addOperation(operation)
        }
                
        return newQueue
    }
    
    func hasActiveOperations(operations: [Operation], current: Operation) -> Bool {
        for operation in operations {
            if operation.isExecuting, operation != current {
                return true
            }
        }
        
        return false
    }
    
    func initQueue() {
        eventsQueue.maxConcurrentOperationCount = 1
    }
    
    func swapQueueOperations() {
        var newOperations: [EventOperation] = []
        let requests = uiRequests
        let names = uiNames
        uiRequests = []
        uiNames = []
                
        for (index, request) in requests.enumerated() {
            let operation = EventOperation()
            operation.delegate = self
            operation.eventBlock = request
            if names.count > index {
                operation.name = names[index]
            }
            
            newOperations.append(operation)
        }
                
        let new = addToHeadOperations(operations: newOperations, queueToAdd: eventsQueue)
        
        eventsQueue = new
        eventsQueue.isSuspended = false
    }
}

// MARK: - EventOperationDelegate

extension ThreadsManager: EventOperationDelegate {
    func eventOperationFinished(wasExecuting: Bool, operation: EventOperation) {
        func finishCurrentOperation() {
            if wasExecuting {
                operation._executing = false
            }
            operation._finished = true
            operation.eventBlock = nil
        }
        
        if !hasActiveOperations(operations: eventsQueue.operations, current: operation) && wasRequest {
            eventsQueue.isSuspended = true
            finishCurrentOperation()
            swapQueueOperations()
        } else {
            finishCurrentOperation()
            if wasRequest, eventsQueue.operationCount == 0 {
                eventsQueue.isSuspended = true
                swapQueueOperations()
            }
        }
    }
}
