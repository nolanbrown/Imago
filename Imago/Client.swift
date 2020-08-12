//
//  Client.swift
//  Imago
//
//  Created by Nolan Brown on 7/21/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

class Client : Conductor2 {
    
    private lazy var _registerRetryTimer: DispatchSourceTimer = {
        let interval: DispatchTimeInterval =  DispatchTimeInterval.seconds(1)
        let timer = DispatchSource.makeTimerSource()
        timer.setEventHandler(handler: register)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        return timer
    }()
    private var _retryingRegistration: Bool = false
    private var _messagePort: CFMessagePort?
    var _identifier: String
    var _server: Server
    var onRegistration : ((Client) -> Void)? = nil
    var receivedNewFrame : ((Frame) -> Void)? = nil

    
    override init(serverName: String? = nil) {
        _identifier = UUID().uuidString
        _server = Server(serverName: "\(serverName!).\(_identifier)")
        super.init(serverName: serverName)
        _server.receivedNewFrameData = receivedNewFrameDataHandler
        _server.start()
    }
    
    override func isClient() -> Bool {
        return true
    }
    
    func invalidate() {
        _registerRetryTimer.suspend()
        _messagePort = nil
    }
    
    public func register() {
        if _messagePort == nil {
            if let port = CFMessagePortCreateRemote(nil, serverName() as CFString) {
                dlog("CONNECTED \(port)")
                _messagePort = port
                _registerRetryTimer.suspend()
                _retryingRegistration = false
            }
            else {
                dlog("NOT CONNECTED \(self)")

                // We couldn't connect to the remote port. Maybe it hasn't been opened yet??
                if _retryingRegistration == false {
                    _retryingRegistration = true
                    _registerRetryTimer.resume()
                }

                return
            }

        }

        let request = Request(port: _messagePort!, callerID: .Register, str: _identifier)
        let response = sendRequest(request)
        if response.isSuccess() {
            let id = response.asString()!
            didRegister(id)
        }
        else {
            dlog("Error during registration: \(response)")
            // We should retry here..
        }
    }
    
    private func didRegister(_ identifier: String) {
        if identifier != _identifier {
            dlog("Invalid registration identifier found \(identifier) != \(_identifier)")
        }
        else if onRegistration != nil {
            DispatchQueue.main.async { [unowned self] in
                self.onRegistration!(self)
            }
        }
    }
    
    func receivedNewFrameDataHandler(_ data: Data) {
        let pre_deserailize = mach_absolute_time()

        let frame = Frame.deserialize(fromData: data)
        let post_deserailize = mach_absolute_time()
        flog(frame!, "deserailize began", timestamp: pre_deserailize)
        flog(frame!, "deserailize ended", timestamp: post_deserailize)
        
        if receivedNewFrame != nil {
            receivedNewFrame!(frame!)
        }
    }
    
    func getFrame() -> Frame? {
        guard let _messagePort = _messagePort else {
            dlog("_messagePort is nil")
            self.register()
            return nil
        }
        let prerequest = mach_absolute_time()
        let request = Request(port: _messagePort, callerID: .GetFrame, str: _identifier)
        let response = sendRequest(request)
        let postrequest = mach_absolute_time()

        if response.isSuccess() {
            let data = response.data
            if data!.count > 0 {
                let pre_deserailize = mach_absolute_time()

                let frame = Frame.deserialize(fromData: data!)
                let post_deserailize = mach_absolute_time()
                
                flog(frame!, "request began", timestamp: prerequest)
                flog(frame!, "request completed", timestamp: postrequest)
                flog(frame!, "deserailize began", timestamp: pre_deserailize)
                flog(frame!, "deserailize ended", timestamp: post_deserailize)

                return frame
            }
        }
        else {
            dlog("Server error response: \(response) ")

        }
        return nil
    }
    
    func _registerRetryHandler() {
        self.register()
    }

}
