//
//  main.swift
//  ReallyMuteIt
//
//  Created by Gervasio Marchand on 10/26/17.
//  Copyright © 2017 Gervasio Marchand. All rights reserved.
//

import Foundation
import CoreAudio

func printOptions() {
    let lookup = NameToIdDict()
    stdout.write("Options:\n".data(using: String.Encoding.utf8)!)
    for e in (lookup?.keys)!{
        stdout.write(e.description.data(using: String.Encoding.utf8)!)
        stdout.write("\n".data(using: String.Encoding.utf8)!)
    }
}

let stdout = FileHandle.standardOutput

if(CommandLine.argc == 1){
    stdout.write("Missing input device name.\n".data(using: String.Encoding.utf8)!)
    printOptions()
    exit(1)
}

if(CommandLine.argc != 2){
    stdout.write("Too many arguments, only specify the input device name".data(using: String.Encoding.utf8)!)
    exit(1)
}

var lookup = NameToIdDict()
var lookupValue = lookup![CommandLine.arguments[1]]
if(lookupValue == nil){
    stdout.write("Invalid input device name.\n".data(using: String.Encoding.utf8)!)
    printOptions()
    exit(1)
}

let deviceId: NSNumber = lookupValue as! NSNumber

var hog: AudioObjectPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyHogMode, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster);
var process: pid_t = -1;
let size: UInt32 = UInt32(MemoryLayout<pid_t>.size);

// mute it!
let status = AudioObjectSetPropertyData(AudioDeviceID(truncating: deviceId), &hog, 0, nil, size, &process);

if(kAudioHardwareNoError != status) {
    stdout.write("Could not hog the device :S".data(using: String.Encoding.utf8)!)
    exit(0)
}

var address = ""
do {
    let data = try Data(contentsOf: URL(fileURLWithPath: "/Library/Application Support/SteelSeries Engine 3/coreProps.json"), options: .mappedIfSafe)
    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
    if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
        address = (jsonResult["address"] as? String)!
    }
} catch {
}

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

sendEvent(address: address)

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

while(true){
    sendHeartbeat(address: address)
    sleep(5)
}
