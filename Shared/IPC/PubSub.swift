//
//  PubSub.swift
//  Imago
//
//  Created by Nolan Brown on 7/24/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreFoundation

let PortInvalidationCallback : CFMessagePortInvalidationCallBack = {
    (port: CFMessagePort?, info: UnsafeMutableRawPointer?) -> Void in
    print("PortInvalidationCallback \(String(describing: port))")
}

/*
 CFMessagePortCallBack
 
 All CFMessagePortCreateLocal methods are provided PortRequestCallback as the callback function. It's here we do:
 1. Determine what type the request is (ie CallerID)
 2. Load the related initialized Conductor object
 3. Process the request
 
 */
let ServerPortCallback : CFMessagePortCallBack = {
    (port: CFMessagePort?, messageID: Int32, data: CFData?, info: UnsafeMutableRawPointer?) -> Unmanaged<CFData>? in

    let callbackID = CallerID(rawValue: messageID)
    
    var serverInstance : PubSub?
    if info != nil {
        serverInstance = unsafeBitCast(info, to: PubSub.self)
    }
    if serverInstance == nil {
        print("ERROR: PubSub Instance Unavailable")
        return nil
    }
    
    var requestData: Data?
    if data != nil && CFDataGetLength(data!) > 0 {
        requestData = data! as Data
    }
        
    guard let callerID = callbackID else {
        return nil
    }
    
    guard let responseData = serverInstance!.receivedRequest(requestData, callerID) else {
        return nil
    }
    return Unmanaged.passRetained(responseData as CFData)
}


enum PortConnectionStatus {
    case Ready
    case Connecting
    case Connected
    case Disconnected // A connect was made invalid
    case Closed // A connection was closed
}


typealias PortConnectionStatusChangedCallback = (PortConnection, PortConnectionStatus)->Void

class PortConnection : Hashable, Identifiable, CustomDebugStringConvertible  {
    var automaticallyReconnect: Bool = true
    var maxConnectionAttempts: Int? = nil
    var retryConnectionInterval: Int = 1
    var timeout: Double = 10.0
    var lastResponseTime: Date? = nil
    
    var _queue: DispatchQueue  = DispatchQueue(label: "PortConnection", qos: .userInteractive)

    private lazy var _retryConnectionTimer: RepeatingTimer = {
        let timer = RepeatingTimer(secondsInterval: retryConnectionInterval) //, queue: _queue)
        timer.eventHandler = _connect
        return timer
    }()
    
    private var _numConnectionAttempts: Int = 0

    internal let _runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode //CFRunLoopMode.commonModes

    private var _remotePort: CFMessagePort?
    private let _remotePortName: String
    
    private var _retryingConnection: Bool = false
    
    public private(set) var status: PortConnectionStatus {
        didSet {
            self.onStatusChanged?(self, self.status)
        }
    }
    
    var onStatusChanged: PortConnectionStatusChangedCallback?

    private var _onConnect: PortConnectionStatusChangedCallback?
    
    deinit {
        self.close()
        //_retryConnectionTimer.cancel()
    }
    
    public init(_ portName: String, queue: DispatchQueue? = nil) {
        if queue != nil {
            _queue = queue!
        }
        _remotePortName = portName
        status = .Ready
            
        dlog("Using \(_remotePortName) for Connection")
    }
    
    var debugDescription: String {
        return "\(String(describing: type(of: self)))(port:\(portName()) status:'\(String(describing: type(of: status)))')"
    }
    
    //var model: String
    static func == (lhs: PortConnection, rhs: PortConnection) -> Bool {
        return lhs.portName() == rhs.portName()
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_remotePortName)
    }
    
    func isConnected() -> Bool {
        if _remotePort == nil {
            return false
        }
        return true
    }
    
    
    func portName() -> String {
        return _remotePortName
    }

    
    func connect(_ onConnect: PortConnectionStatusChangedCallback? = nil) {
        // Don't attempt to connect if we are trying or are already connected
        if status == .Connecting || status == .Connected {
            if onConnect != nil && status == .Connected {
                onConnect!(self, status)
            }
            return
        }
        if onConnect != nil {
            _onConnect = onConnect
        }
        status = .Connecting
        //_connect()
        if _remotePort == nil {
            _retryConnectionTimer.resume()
        }
    }
    
    func close() {
        _invalidatePort()
        _onConnect = nil
        _retryConnectionTimer.suspend()
        self.status = .Closed
    }
    
    func sendRequest(_ callerID: CallerID, data: Data? = nil, str: String? = nil, onCompletion: @escaping((Response)->Void)) {
        DispatchQueue.main.async { [unowned self] in
            let messageID = callerID.rawValue
            
            var requestData: CFData? = nil
            if str != nil {
                requestData = str!.data(using: .utf8)! as CFData

            }
            else if data != nil {
                requestData = data! as CFData
            }
            
            
            var responseRawData: Unmanaged<CFData>?

            let status = CFMessagePortSendRequest(self._remotePort,
                                         messageID,
                                         requestData,
                                         self.timeout,
                                         self.timeout,
                                         self._runLoopMode.rawValue,
                                         &responseRawData)
            
            var responseData: Data?
            if responseRawData != nil {
                responseData = responseRawData!.takeRetainedValue() as Data
                if responseData?.count == 0 {
                    responseData = nil
                }
            }
            
            self.lastResponseTime = Date()
            let response = Response(callerID: callerID, status: status, data: responseData)
            onCompletion(response)
        }

    }
    func sendRequest(_ callerID: CallerID, data: Data? = nil, str: String? = nil) -> Response {
        if status != .Connected {
            return Response(callerID: callerID, status: kCFMessagePortIsInvalid, data: nil)
        }
        
        let messageID = callerID.rawValue
        
        var requestData: CFData? = nil
        if str != nil {
            requestData = str!.data(using: .utf8)! as CFData

        }
        else if data != nil {
            requestData = data! as CFData
        }
        
        
        var responseRawData: Unmanaged<CFData>?

        let status = CFMessagePortSendRequest(_remotePort,
                                     messageID,
                                     requestData,
                                     timeout,
                                     timeout,
                                     _runLoopMode.rawValue,
                                     &responseRawData)
        
        var responseData: Data?
        if responseRawData != nil {
            responseData = responseRawData!.takeRetainedValue() as Data
            if responseData?.count == 0 {
                responseData = nil
            }
        }
        self.lastResponseTime = Date()

        let response = Response(callerID: callerID, status: status, data: responseData)
        return response
    }
    
    
    private func _invalidatePort() {
        if _remotePort == nil {
            CFMessagePortInvalidate(_remotePort)
            _remotePort = nil
        }
    }
    
    private func _resetConnection() {
        _invalidatePort()
        _numConnectionAttempts = 0
        _retryConnectionTimer.resume()
        status = .Connecting

    }
    
    private func _didConnect() {
        if status == .Connected {
            return
        }
        status = .Connected
        DispatchQueue.main.async { [unowned self] in
            self._onConnect?(self, self.status)
            
            self._onConnect = nil
        }
    }
    
    // _retryConnectionTimer handler
    private func _connect() {
        _retryingConnection = true
        dlog("CONNECTING ... \(String(describing: _remotePort))")
        if _remotePort == nil {
            // Close the connection after reaching the max number of attempts
            if maxConnectionAttempts != nil {
                if _numConnectionAttempts >= maxConnectionAttempts! {
                    self.close()
                    return
                }
            }

            
            if let port = CFMessagePortCreateRemote(nil, _remotePortName as CFString) {
                dlog("CONNECTED \(port)")
                _remotePort = port
            }
            else {
                // We couldn't connect to the remote port. Maybe it hasn't been opened yet??
                _numConnectionAttempts += 1
                return
            }
        }
        
        _numConnectionAttempts = 0
        _retryConnectionTimer.suspend()
        _retryingConnection = false
        
        _didConnect()
    }
}



class Subscriber: PubSub {
    let identifier: String = UUID().uuidString

    
    private lazy var _periodicRegistrationTimer: RepeatingTimer = {
        let timer = RepeatingTimer(secondsInterval: 5) //, queue: _queue)
        timer.eventHandler = _periodicRegistration
        return timer
    }()
    
    private var _publisherConnection: PortConnection
    private var _portName: String
    private var _port: CFMessagePort?

    fileprivate var _runLoopSource: CFRunLoopSource?
    
    var receivedNewFrame : ((Frame) -> Void)? = nil
    var receivedNewFrameData : ((Data) -> Void)? = nil

    override init(publisherPortName: String) {
        _portName = "\(publisherPortName).\(identifier)"
        
        // Connect to publisher and register so we can start receiving data
        _publisherConnection = PortConnection(publisherPortName)
        
        super.init(publisherPortName: publisherPortName)

        // Create port for Publisher to call
        let (createdPort, createdRunLoopSource) = createLocalPort(_portName)

        _port = createdPort
        _runLoopSource = createdRunLoopSource
        dlog("Started Subscriber at \(_portName)")

        _publisherConnection.onStatusChanged = self.onPublisherConnectionStatusChange
        
    }
    
    func teardown() {
        stopLocalPort(port: _port, runLoopSource: _runLoopSource)
        _port = nil
        _runLoopSource = nil
    }
    
    override func start() {
        _publisherConnection.connect { [weak self] (conn, status) in
            let response = conn.sendRequest(.Register, str: self?.identifier)
            dlog("received publisher register response \(response)")
            if response.isSuccess() {

            }
        }
        _periodicRegistrationTimer.resume()

    }
    override func stop() {
        _periodicRegistrationTimer.suspend()
        // we don't want to get any more frames
        
    }
    
    deinit {
        _periodicRegistrationTimer.suspend()
        _publisherConnection.close()
        stopLocalPort(port: _port, runLoopSource: _runLoopSource)
        _port = nil
        _runLoopSource = nil
    }
    
    // can we make this run on a concucrent queue
    fileprivate override func receivedRequest(_ data: Data?, _ callerID: CallerID) -> Data? {
        //dlog("Subscriber receivedRequest \(callerID) \(data) \(Thread.current) \(Thread.isMainThread)")

        switch callerID {
            case .ReceiveFrame:
                guard let frame_data = data else {
                    return nil
                }
                
                if receivedNewFrameData != nil {
                    receivedNewFrameData?(frame_data)

                    return Response.Code.OK.data()

                }
                return Response.Code.NotAvailable.data()
        default:
            break
        }
        return nil
    }
    
    private func onPublisherConnectionStatusChange(connection: PortConnection, status: PortConnectionStatus) {
        dlog("onPublisherConnectionStatusChange connection \(connection) \(status)")
        if status == .Connected {
            dlog("connected to publisher \(connection) \(status)")
        }

    }
    
    private func _periodicRegistration() {
        let response = _publisherConnection.sendRequest(.Register, str: self.identifier)
        if response.isSuccess() {
            
        }
        else {
            dlog("not connected to publisher")
            _publisherConnection.close()
            _publisherConnection = PortConnection(self._publisherPortName)
            _publisherConnection.onStatusChanged = self.onPublisherConnectionStatusChange
            _publisherConnection.connect()

        }
    }

}

// Handles connection management and setting up local connections
class PubSub {
    fileprivate var _publisherPortName: String
    private var _publisherPort: CFMessagePort?
    private var _publisherRunLoopSource: CFRunLoopSource?

    internal let _runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode //CFRunLoopMode.commonModes
    
    private var _connections: Set<PortConnection> = []
    
    fileprivate var _queue: DispatchQueue  = DispatchQueue(label: "PubSub", qos: .userInteractive)
    
    public init(publisherPortName: String) {
        dlog("PubSub INIT \(publisherPortName)")
        _publisherPortName = publisherPortName
    }
    
    func publisherName() -> String {
        return _publisherPortName
    }
    
    
    func getSubscriberMetrics() -> Dictionary<String, Any> {
        var metrics: [String: Any] = ["NumSubscribers": _connections.count]
        
        var subscribers: [[String:Any?]] = []
        for conn in _connections {
            let subscriber: [String : Any?] = ["LastResponseTime":conn.lastResponseTime, "ID": conn.portName(), "Connected": conn.isConnected()]
            subscribers.append(subscriber)
        }
        metrics["Subscribers"] = subscribers
        return metrics
    }
    
    func isRunning() -> Bool {
        if _publisherPort != nil && _publisherRunLoopSource != nil {
            return true
        }
        return false
    }
    
    func start() {
        if _publisherPort != nil {
            return
        }
        // Create port for Publisher to call
        let (createdPort, createdRunLoopSource) = createLocalPort(_publisherPortName)
        
        _publisherPort = createdPort
        _publisherRunLoopSource = createdRunLoopSource

    }
    func stop() {
        stopLocalPort(port: _publisherPort, runLoopSource: _publisherRunLoopSource)
        _publisherPort = nil
        _publisherRunLoopSource = nil
    }
    
    
    func publishFrameData(_ frameData: Data) {
        for conn in _connections {
            let response = conn.sendRequest(.ReceiveFrame, data: frameData)
            if response.isSuccess() {
                //print("response \(response)")
            }
        }
    }
    
    private func onConnectionStatusChange(connection: PortConnection, status: PortConnectionStatus) {
        dlog("onConnectionStatusChange connection \(connection) \(status)")
        if status == .Connected {
//            dlog("sending ping to \(connection)")
//            let response = connection.sendRequest(.Ping)
//            print("ping response \(response)")
        }
    }
    
    private func addConnectionByIdentifier(_ identifier: String) -> Bool {
        let clientName = "\(publisherName()).\(identifier)"
        let conn = PortConnection(clientName)
        if !_connections.contains(conn) {
            _connections.insert(conn)
            conn.onStatusChanged = self.onConnectionStatusChange
            conn.connect()
            return true
        }
        return false
    }
    
    fileprivate func receivedRequest(_ data: Data?, _ callerID: CallerID) -> Data? {

        switch callerID {
            case .Register:
                guard let id_data = data else {
                    return nil
                }
                let identifier = String(data: id_data, encoding: .utf8)!

                dlog("Recieved \(callerID) request from client \(identifier)")

                if addConnectionByIdentifier(identifier) { // we added the connection
                    return Response.Code.Success.data()
                }
                return Response.Code.OK.data()


        default:
            break
        }
        return nil
    }
    
    fileprivate func createLocalPort(_ portName: String) -> (CFMessagePort?, CFRunLoopSource?) {
        //return DispatchQueue.main.sync {
            var context = CFMessagePortContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
            if let port = CFMessagePortCreateLocal(nil, portName as CFString, ServerPortCallback, &context, nil) {
                CFMessagePortSetInvalidationCallBack(port, PortInvalidationCallback)
                
                CFMessagePortSetDispatchQueue(port, _queue)

                return (port, nil)
            }
            return (nil, nil)
        //}

    }

    fileprivate func stopLocalPort(port: CFMessagePort?, runLoopSource: CFRunLoopSource? ) {
        if port != nil {
            CFMessagePortInvalidate(port)
        }
        if runLoopSource != nil {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, _runLoopMode)
        }
    }
    
}
