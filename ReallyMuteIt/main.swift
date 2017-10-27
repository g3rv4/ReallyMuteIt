//
//  main.swift
//  ReallyMuteIt
//
//  Created by Gervasio Marchand on 10/26/17.
//  Copyright © 2017 Gervasio Marchand. All rights reserved.
//

import Foundation
import CoreAudio

let stdout = FileHandle.standardOutput

var hog: AudioObjectPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyHogMode, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster);
var process: pid_t = -1;
let size: UInt32 = UInt32(MemoryLayout<pid_t>.size);

var deviceToIgnore = "";
if CommandLine.argc >= 2 {
    deviceToIgnore = CommandLine.arguments[1]
}

var devices = IdToName()

for deviceId in (devices?.keys)! {
    if (devices![deviceId] as! String) == deviceToIgnore {
        continue
    }
    
    // mute it!
    let status = AudioObjectSetPropertyData(AudioDeviceID(truncating: deviceId as! NSNumber), &hog, 0, nil, size, &process);
    
    if(kAudioHardwareNoError != status) {
        stdout.write("Could not hog the device :S".data(using: String.Encoding.utf8)!)
        exit(0)
    }
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

if(address != ""){
    sendEvent(address: address)
    
    while(true){
        sendHeartbeat(address: address)
        sleep(5)
    }
} else {
    // wait 4eva
    let sema = DispatchSemaphore(value: 0)
    sema.wait()
}
