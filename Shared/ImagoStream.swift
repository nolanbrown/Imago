//
//  ImagoStream.swift
//  Imago
//
//  Created by Nolan Brown on 7/20/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreImage

class ImagoStream {
    private var _subscriber: Subscriber?
    private var _fps: Int = 30
    private var _startReceivingFrames: Bool = true
    private var _isRegistered: Bool = false
    private var _isTimerRunning: Bool = false
    private var _queue: DispatchQueue  = DispatchQueue(label: "com.Imago.ImagoStream")
    private var _currentFrame: Frame?
    private var _pubsub: PubSub = PubSub(publisherPortName:IMAGO_SERVER_NAME)

    private var _renderedFrames: [UInt64] = []
    private var _startTS: UInt64 = 0

    private var _sequenceNumber: UInt64 = 0
    
    var isRunning: Bool = false

    var receivedFrame : ((Frame) -> Void)? = nil

    init() {
        print("ImagoStream INIT")
    }

    func framesPerSecond() -> Int {
        return _fps
    }
    
    func start() {
        if !isRunning {
            _startReceivingFrames = true
            isRunning = true
            if _subscriber == nil {
                _subscriber = Subscriber(publisherPortName: IMAGO_SERVER_NAME)
                _subscriber!.start()
                _subscriber!.receivedNewFrameData = setFrameData
            }
        }
        _subscriber!.start()
        _subscriber!.receivedNewFrameData = setFrameData

    }

    func stop() {
        _subscriber!.stop()
        _startReceivingFrames = false
        isRunning = false

    }
    
    
    func setFrameData(_ frameData: Data) {

        guard let frame: Frame = Frame.deserialize(fromData:frameData) else {
            return
        }
        
        if _currentFrame != nil && _currentFrame?.id == frame.id {
            return
        }
        if _currentFrame == nil { // first frame
            _startTS = mach_absolute_time()
        }
        
        var newFrame = frame
        if receivedFrame != nil {

            receivedFrame!(newFrame)

            if _currentFrame?.timestamp != nil {
                let _ = newFrame.elapsedSeconds(_currentFrame!.timestamp)
            }
        }
        _currentFrame = newFrame

        _sequenceNumber += 1

    }
    
}
