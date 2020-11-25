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
    
    let manager = ThreadsManager()
    
    fileprivate lazy var notesList: [String] = {
        return ["a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m", "n", "o", "p", "r", "s", "u"]
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runTestLoop(isInitial: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [weak self] in
            guard let self = self else { return }
            
            self.runTestLoop(isInitial: false)
        })
    }
}

// MARK: - Fileprivate

fileprivate extension ViewController {
    func runTestLoop(isInitial: Bool) {
        let from = isInitial ? 0 : 10
        let to = isInitial ? 10 : 20
        
        for i in from..<to {
            manager.addOperation(thread: .background, name: "hello loop") { (completion) in
                sleep(1)
                print("hello \(i)")
                completion(true)
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manager.addOperation(thread: .main, name: "main UI") { (completion) in
            sleep(1)
            print("UI request")
            completion(true)
        }
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
