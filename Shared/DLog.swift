//
//  DLog.swift
//  Imago
//
//  Created by Nolan Brown on 7/19/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

func dlog(_ message: Any = "", function: String = #function) {
    NSLog("Imago: \(function): \(message)")
}

func flog(_ frame: Frame, _ message: Any = "", timestamp: UInt64 = mach_absolute_time()) {
    //let diff =  TimeInterval(timestamp - UInt64(frame.timestamp)) / TimeInterval(NSEC_PER_SEC)
    //NSLog("Frame \(frame.id): \(message) - \(diff)s")
}

func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
}
