//
//  ViewController.swift
//  ConcurrencyTest
//
//  Created by Yuriy Holovatskyi on 15.02.18.
//  Copyright © 2018 noname. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var wasRequest: Bool = false
    var queue = OperationQueue()
    
    fileprivate lazy var notesList: [String] = {
        return ["a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m", "n", "o", "p", "r", "s", "u"]
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        queue.maxConcurrentOperationCount = 1
        
        for i in 0..<10 {
            let operation = EventOperation()
            operation.eventBlock = { (completionBlock: OperationCompletion) -> () in
                sleep(1)
                print("hello \(i)")
                completionBlock(true)
            }
                        
            queue.addOperation(operation)
        }
        
        queue.addObserver(self, forKeyPath: "operations", options: .new, context: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [weak self] in
            guard let strongSelf = self else { return }
            
            for i in 10..<20 {
                let operation = EventOperation()
                operation.eventBlock = { (completionBlock: OperationCompletion) -> () in
                    sleep(1)
                    print("hello \(i)")
                    completionBlock(true)
                }
                
                strongSelf.queue.addOperation(operation)
            }
        })
    }
}

// MARK: - Private

extension ViewController {
    
    func addOperation(operation: EventOperation, toHead: OperationQueue) -> OperationQueue {
        wasRequest = false
        
        let newQueue = OperationQueue()
        newQueue.maxConcurrentOperationCount = 1
        newQueue.addOperation(operation)
        
        let operations = toHead.operations as! [EventOperation]
        
        operations.forEach{
            let opert = EventOperation()
            opert.eventBlock = $0.eventBlock
            newQueue.addOperation(opert)
        }
        
        return newQueue
    }
    
    func hasActiveOperations(operations: [Operation]) -> Bool {
        
        for operation in operations {
            if operation.isExecuting {
                return true
            }
        }
        
        return false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if wasRequest {
            queue.isSuspended = true
        }
        
        if let obj = object as? OperationQueue, obj == queue, let currentkeypath = keyPath,
            currentkeypath == "operations", let change = change, let operations = change[.newKey] as? [Operation] {
            
            if !hasActiveOperations(operations: operations) && wasRequest {
                let operation = EventOperation()
                
                operation.eventBlock = { (completionBlock: OperationCompletion) -> () in
                        sleep(1)
                        print("UI request")
                        completionBlock(true)
                }
                
                queue.removeObserver(self, forKeyPath: "operations")
                let new = addOperation(operation: operation, toHead: queue)
                
                queue = new
                queue.addObserver(self, forKeyPath: "operations", options: .new, context: nil)
            }
        }
    }
    
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        wasRequest = true
    }
    
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "someCell") as UITableViewCell? else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "someCell")
            
            cell.textLabel?.text = notesList[indexPath.row]
            
            return cell
        }
        
        cell.textLabel?.text = notesList[indexPath.row]
        
        return cell
    }
    
}
