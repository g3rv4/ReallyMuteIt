//
//  GameSense.swift
//  ReallyMuteIt
//
//  Created by Gervasio Marchand on 10/27/17.
//  Copyright © 2017 Gervasio Marchand. All rights reserved.
//

import Foundation

// Send event to gamesense
func sendEvent(address: String) {
    let sessionConfig = URLSessionConfiguration.default
    
    /* Create session, and optionally set a URLSessionDelegate. */
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    guard let URL = URL(string: "http://" + address + "/game_event") else {return}
    var request = URLRequest(url: URL)
    request.httpMethod = "POST"
    
    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    // JSON Body
    let bodyObject: [String : Any] = [
        "event": "MUTE",
        "data": [
            "value": 1
        ],
        "game": "MUTE_IT"
    ]
    request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
    
    let sema = DispatchSemaphore(value: 0)
    /* Start a new Task */
    let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if (error == nil) {
            // Success
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("URL Session Task Succeeded: HTTP \(statusCode)")
        }
        else {
            // Failure
            print("URL Session Task Failed: %@", error!.localizedDescription);
        }
        sema.signal()
    })
    task.resume()
    session.finishTasksAndInvalidate()
    sema.wait()
}

func sendHeartbeat(address: String) {
    let sessionConfig = URLSessionConfiguration.default
    
    /* Create session, and optionally set a URLSessionDelegate. */
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    guard let URL = URL(string: "http://" + address + "/game_heartbeat") else {return}
    var request = URLRequest(url: URL)
    request.httpMethod = "POST"
    
    // Headers
    
    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    // JSON Body
    
    let bodyObject: [String : Any] = [
        "game": "MUTE_IT"
    ]
    request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
    
    let sema = DispatchSemaphore(value: 0)
    /* Start a new Task */
    let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if (error == nil) {
            // Success
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("URL Session Task Succeeded: HTTP \(statusCode)")
        }
        else {
            // Failure
            print("URL Session Task Failed: %@", error!.localizedDescription);
        }
        sema.signal()
    })
    task.resume()
    session.finishTasksAndInvalidate()
    sema.wait()
}
