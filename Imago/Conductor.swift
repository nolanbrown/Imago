//
//  Conductor.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//



class Conductor {
    private var _serverName: String
    
    private let _timeout: Double = 10.0
    
    internal let _runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode //CFRunLoopMode.commonModes

    private lazy var _registerRetryTimer: DispatchSourceTimer = {
        let interval: DispatchTimeInterval =  DispatchTimeInterval.seconds(1)
        let timer = DispatchSource.makeTimerSource()
        timer.setEventHandler(handler: register)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        return timer
    }()
    
    private var _serverPort: CFMessagePort?
    private var _registeredClients: Set<CFMessagePort> = []

    private var _retryingRegistration: Bool = false

    var _identifier: String
    
    var onRegistration : ((Client) -> Void)? = nil
    var receivedNewFrame : ((Frame) -> Void)? = nil
    
    public init(serverName: String? = nil) {
        
        if serverName == nil {
            _serverName = Bundle.main.bundleIdentifier!
        }
        else {
            _serverName = serverName!
        }
        dlog("Using \(_serverName) for Conductor Server")

    }
    
    func serverName() -> String {
        return _serverName
    }
    

    
    func sendRequest(_ request: Request) -> Response {
        let messageID = request.messageID()
        let port = request.port
        
        let requestData = request.asCFData()

        
        
        var responseRawData: Unmanaged<CFData>?

        let status = CFMessagePortSendRequest(port,
                                     messageID,
                                     requestData,
                                     _timeout,
                                     _timeout,
                                     _runLoopMode.rawValue,
                                     &responseRawData)
        
        var responseData: Data?
        if responseRawData != nil {
            responseData = responseRawData!.takeRetainedValue() as Data
        }
        
        return Response(callerID: request.callerID, status: status, data: responseData)
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
 
    
    
    func invalidate() {
        _registerRetryTimer.suspend()
        _messagePort = nil
    }
    
    //
    
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


class Conductor2 {
    private var _serverName: String
    
    private let _timeout: Double = 10.0
    
    internal let _runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode //CFRunLoopMode.commonModes

    public init(serverName: String? = nil) {
        
        if serverName == nil {
            _serverName = Bundle.main.bundleIdentifier!
        }
        else {
            _serverName = serverName!
        }
        dlog("Using \(_serverName) for Conductor Server")

    }
    
    func serverName() -> String {
        return _serverName
    }
    
    func isServer() -> Bool {
        return false
    }
    
    func isClient() -> Bool {
        return !isServer()
    }

    
    func sendRequest(_ request: Request) -> Response {
        let messageID = request.messageID()
        let port = request.port
        
        let requestData = request.asCFData()

        
        
        var responseRawData: Unmanaged<CFData>?

        let status = CFMessagePortSendRequest(port,
                                     messageID,
                                     requestData,
                                     _timeout,
                                     _timeout,
                                     _runLoopMode.rawValue,
                                     &responseRawData)
        
        var responseData: Data?
        if responseRawData != nil {
            responseData = responseRawData!.takeRetainedValue() as Data
        }
        
        return Response(callerID: request.callerID, status: status, data: responseData)
    }
 
}
