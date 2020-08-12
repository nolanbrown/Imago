//
//  Publisher.swift
//  Imago
//
//  Created by Nolan Brown on 7/16/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

class Server : Conductor2 {

    fileprivate var _messagePort: CFMessagePort?
    fileprivate var _runLoopSource: CFRunLoopSource?
    fileprivate var _queue: DispatchQueue  = DispatchQueue(label: "com.nolanbrown.Imago.Server", qos: .userInteractive)

    //@objc weak var delegate: ConductorProtocol?
    fileprivate var _registeredClientIDs: Set<String> = []
    fileprivate var _registeredClients: Set<CFMessagePort> = []

    var subscribedHandler : (() -> Void)? = nil
    var getFrameData : (() -> Data?)? = nil

    var receivedNewFrameData : ((Data) -> Void)? = nil

    deinit {
        stop()
    }
    
    override func isServer() -> Bool {
        return true
    }
    
    
    // PUBLIC METHODS
    func start() {
        // Don't try to start the publisher again
        if _messagePort != nil {
            return
        }
        
        let (createdPort, createdRunLoopSource) = createLocalPort(serverName())
        _messagePort = createdPort
        _runLoopSource = createdRunLoopSource
        dlog("Started Server at \(serverName()): \(_messagePort)")
    }
    
    func stop() {
        if _messagePort != nil {
            CFMessagePortInvalidate(_messagePort)
            _messagePort = nil
        }
        if _runLoopSource != nil {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, _runLoopMode)
            _runLoopSource = nil
        }
    }
    func sendFrameToClients(_ frame: Frame) {
        guard let data = frame.serialize() else {
            print("no frame data \(frame)")
            return
        }
        for client in _registeredClients {
            let request = Request(port: client, callerID: .ReceiveFrame, data: data)
            let response = sendRequest(request)
            if response.isSuccess() {
                print("response \(response)")
            }
        }
    }
    
    private func addClient(_ identifier: String) {
        _registeredClientIDs.insert(identifier)

        let clientName = "\(serverName()).\(identifier)"
        
        if let port = CFMessagePortCreateRemote(nil, clientName as CFString) {
            if !_registeredClients.contains(port) {
                _registeredClients.insert(port)
            }
        }
    }
    
    fileprivate func receivedRequest(_ data: Data?, _ callerID: CallerID) -> Data? {
        
//        let receivedData: Data?
//        var identifier: String?
//        // We will always expected publisher data to be an  indentifier
//        if data != nil && CFDataGetLength(data!) > 0 {
//            let receivedData = data! as Data
//            identifier = String(data: receivedData, encoding: .utf8)!
//        }
        
        switch callerID {
            case .Register:
                guard let id_data = data else {
                    return nil
                }
                let identifier = String(data: id_data, encoding: .utf8)!

                dlog("Recieved \(callerID) request from client \(identifier)")

                addClient(identifier)
                return identifier.data(using: .utf8)
            
            case .GetFrame:
                
                if getFrameData != nil {
                    return getFrameData!()
                }
            case .ReceiveFrame:
                guard let frame_data = data else {
                    return nil
                }
                receivedNewFrameData?(frame_data)
                return "OK".data(using: .utf8)
        default:
            break
        }
        return nil
    }

    private func createLocalPort(_ portName: String) -> (CFMessagePort?, CFRunLoopSource?) {
        var context = CFMessagePortContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        if let port = CFMessagePortCreateLocal(nil, portName as CFString, PortRequestCallback, &context, nil) {
            //CFMessagePortSetInvalidationCallBack(port, PortInvalidationCallback)
            
            let runLoopSource = CFMessagePortCreateRunLoopSource(nil, port, 0);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, _runLoopMode);
            
            CFMessagePortSetDispatchQueue(port, _queue)

            return (port, runLoopSource)
        }
        return (nil, nil)
    }
}

let PortInvalidationCallback : CFMessagePortInvalidationCallBack = {
    (port: CFMessagePort?, info: UnsafeMutableRawPointer?) -> Void in
    print("PortInvalidationCallback \(port)")
}

/*
 CFMessagePortCallBack
 
 All CFMessagePortCreateLocal methods are provided PortRequestCallback as the callback function. It's here we do:
 1. Determine what type the request is (ie CallerID)
 2. Load the related initialized Conductor object
 3. Process the request
 
 */
let PortRequestCallback : CFMessagePortCallBack = {
    (port: CFMessagePort?, messageID: Int32, data: CFData?, info: UnsafeMutableRawPointer?) -> Unmanaged<CFData>? in
    
    let callbackID = CallerID(rawValue: messageID)
    
    var conductorInstance : Server?
    if info != nil {
        conductorInstance = unsafeBitCast(info, to: Server.self)
        //conductorInstance = info!.load(as: Conductor.self)
    }
    if conductorInstance == nil {
        print("ERROR: Conductor Instance Unavailable")
        return nil
    }
    
    var receivedData: Data?
    if data != nil && CFDataGetLength(data!) > 0 {
        receivedData = data! as Data
    }
    
    var portName = conductorInstance!.serverName()
    
    guard let callerID = callbackID else {
        return nil
    }
    
    guard let responseData = conductorInstance!.receivedRequest(receivedData, callerID) else {
        return nil
    }
    return Unmanaged.passRetained(responseData as CFData)
}
