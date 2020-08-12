//
//  CanonCamera.swift
//  Imago
//
//  Created by Nolan Brown on 7/8/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

struct CommandResult : CustomDebugStringConvertible {
    let rawResult: EdsError
    let property: CanonProperty?
    
    init() {
        self.init(EdsError(EDS_ERR_OK), nil)
    }
    
    init(_ rawResult: EdsError) {
        self.init(rawResult, nil)
    }
    
    init(_ rawResult: EdsError, _ property: CanonProperty?) {
        self.rawResult = rawResult
        self.property = property

    }
    init(_ property: CanonProperty) {
        self.init(EdsError(EDS_ERR_OK), property)
    }
    
    func withProperty(_ property: CanonProperty) -> CommandResult {
        return CommandResult(self.rawResult, property)
    }
    
    
    func isOK() -> Bool {
        let isOK = (rawResult == EdsError(EDS_ERR_OK))
        return isOK
    }
    
    // For readability in Command.perform() functions
    func isError() -> Bool {
        return !isOK()
    }
    
    func getResultDescription() -> String {
        return DescriptionForEdsError(self.rawResult)
    }
    
    var debugDescription : String {
        return self.description
    }
    
    var description: String {
        if self.property != nil {
            return "CommandResult(result:\(self.getResultDescription()) property:\(self.property!))"
        }
        
        return "CommandResult(\(self.getResultDescription()))"
    }

}

class CanonCamera : Camera {
    fileprivate var _deviceInfo: EdsDeviceInfo? = nil
    fileprivate var _cameraRef: EdsCameraRef? = nil
    fileprivate var _serialNumber: String? = nil

    fileprivate var _deviceDescription: String
    fileprivate var _rawPort: String
    
    fileprivate var _fps: Int = 30
    fileprivate var _sequence: UInt64 = 0

    fileprivate var _commandQueue: DispatchQueue  = DispatchQueue(label: "com.nolanbrown.imago.CanonCamera.commands") //, qos: .userInteractive)
    
    private lazy var _signal: DispatchSourceUserDataAdd = {
        let signal = DispatchSource.makeUserDataAddSource(queue: self._commandQueue)
        signal.setEventHandler{
            // set frame here

        }
        return signal
    }()
    
    private lazy var _newFrameTimer: DispatchSourceTimer = {
        let interval: DispatchTimeInterval =  DispatchTimeInterval.nanoseconds(Int(NSEC_PER_SEC / UInt64(Double(self._fps))))
        let timer = DispatchSource.makeTimerSource(queue: self._commandQueue)
        timer.setEventHandler(handler: self.newFrameTimerHandler)
        timer.setCancelHandler(handler: self.timerCancelledHandler)
        timer.schedule(deadline: .now(), repeating: interval)
        return timer
    }()
    
    private lazy var _stayAliveTimer: DispatchSourceTimer = {
        let interval: DispatchTimeInterval =  DispatchTimeInterval.seconds(60)
        let timer = DispatchSource.makeTimerSource(queue: self._commandQueue)
        timer.setEventHandler(handler: self.stayAliveTimerHandler)
        timer.schedule(deadline: .now() + interval , repeating: interval)
        return timer
    }()
    
    
    fileprivate var _id: String?
    deinit {
        print("deinit CanonCamera")
        EdsRelease(_cameraRef)
    }
    
//    required init(from decoder: Decoder) throws {
//        super.init(from: decoder)
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        name = try values.decode(String.self, forKey: .name)
//        model = try values.decode(String.self, forKey: .model)
//        identifier = try values.decode(String.self, forKey: .identifier)
//
//    }
    
    init(cameraRef:EdsCameraRef, deviceInfo: EdsDeviceInfo){
        _cameraRef = cameraRef
        _deviceInfo = deviceInfo
        
        EdsRetain(_cameraRef)

        _deviceDescription = withUnsafePointer(to: _deviceInfo!.szDeviceDescription) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        _rawPort = withUnsafePointer(to: _deviceInfo!.szPortName) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        super.init()

        name = _deviceDescription
        identifier = _rawPort
        if let serial = self.serialNumber() {
            identifier = serial
        }

    }
    
    internal func getCameraRef()->EdsCameraRef?{
        return _cameraRef
    }    
    
    func serialNumber() -> String? {
        if _serialNumber != nil {
            return _serialNumber
        }
        if isActive {
            let prop = CanonProperty.forID(EdsPropertyID(kEdsPropID_BodyIDEx))
            let propValue = getEdsPropertyValue(prop)
            _serialNumber = propValue?.stringValue
            return _serialNumber
        }
        return nil
    }
    
//    override func identifier() -> String {
//        return _rawPort
//    }
//
//    override func name() -> String {
//        return _deviceDescription
//
//    }
    
    
    
    override func setActive(active: Bool) {
        var becameActive = active
        
        if active {
            _commandQueue.sync { [unowned self] in
                if self.registerEdsEventHandlers() {
                    if self.openSession() {
                        dlog("open session")
                        
                        if self.setEvfMode() && self.setOutputDevice(toPC: true) {
                            self._newFrameTimer.resume()
                            self._stayAliveTimer.resume()
                            becameActive = true
                            return

                        }
                    }
                }
                becameActive = false
            }
        }
        else {
            _commandQueue.sync { [unowned self] in
                self._newFrameTimer.suspend()
                self._stayAliveTimer.suspend()
                
                self.removeEdsEventHandlers()
                if self.setOutputDevice(toPC: false) {
                    if self.closeSession() {
                        dlog("Closed Session")
                    }
                    else {
                        dlog("Session didn't close")
                    }
                }
                else {
                    dlog("Output device wasn't reset")
                }
            }
        }
        
        super.setActive(active: becameActive)
        
    }


    func stayAliveTimerHandler() {
        if self.setOutputDevice(toPC: true) {
            dlog("Stay alive timer set output device")
        }
        else {
            dlog("Stay alive timer failed to output device")
        }
    }
    
    func newFrameTimerHandler() {
        guard let frame = loadFrame() else {
            return
        }
        self.setFrame(frame)
        flog(frame, "set frame for next request")
        
    }
    
    func timerCancelledHandler() {
        dlog("Timer Cancelled")
    }
    
    
    
}

extension CanonCamera {
    private func openSession() -> Bool {
        let result = CommandResult(EdsOpenSession(_cameraRef))
        if result.isError() {
            if result.rawResult == EDS_ERR_SESSION_ALREADY_OPEN {
                return true
            }
            return false
        }
        return true
    }
    
    private func closeSession() -> Bool {
        let result = CommandResult(EdsCloseSession(_cameraRef))
        if result.isError() {
            if result.rawResult == EDS_ERR_SESSION_NOT_OPEN {
                return true
            }
            return false
        }
        return true
    }
    
    private func setEvfMode() -> Bool {
        var evfMode: EdsUInt32 = 0
        
        let result = CommandResult(EdsGetPropertyData(_cameraRef, EdsPropertyID(kEdsPropID_Evf_Mode), 0, EdsUInt32(MemoryLayout<EdsUInt32>.size), &evfMode))
        if result.isError() {
            return false
        }

        if(evfMode == 0)
        {
            evfMode = 1
            // Set to the camera.
            let setResult = CommandResult(EdsSetPropertyData(_cameraRef, EdsPropertyID(kEdsPropID_Evf_Mode), 0, EdsUInt32(MemoryLayout<EdsUInt32>.size), &evfMode))
            if setResult.isError() {
                return false
            }
        }
        return true
    }
    
    private func setOutputDevice(toPC: Bool = true) -> Bool {
        var device: EdsUInt32 = 0

        // Get Output Device
        let outputDevicePropertyID = EdsPropertyID(kEdsPropID_Evf_OutputDevice)
        let result = CommandResult(EdsGetPropertyData(_cameraRef, outputDevicePropertyID, 0, EdsUInt32(MemoryLayout<EdsUInt32>.size), &device))
        if result.isError() {
            dlog("Get Output Device Failed:  \(result)")

            return false
        }
        
        // Set the current output device.
        if toPC {
            device |= kEdsEvfOutputDevice_PC.rawValue
        }
        else {
            device &= ~kEdsEvfOutputDevice_PC.rawValue
        }

        let setResult = CommandResult(EdsSetPropertyData(_cameraRef, outputDevicePropertyID, 0, EdsUInt32(MemoryLayout<EdsUInt32>.size), &device))
        if setResult.isError() {
            dlog("Set Output Device Failed:  \(setResult)")
            return false
        }
        else {
            dlog("Set Output Device == \(device)")
        }
        return true
    }
    
    func loadFrame() -> Frame? {
        let starts = mach_absolute_time()
                
        var streamRef: EdsStreamRef? = nil
        var imageRef: EdsEvfImageRef? = nil
        let bufferSize:EdsUInt64  = 0
        
        // Create memory stream.
        let createMemoryStreamResult = CommandResult(EdsCreateMemoryStream(bufferSize, &streamRef))
        if createMemoryStreamResult.isError() {
            return nil
        }
        
        // Create EvfImageRef.
        let createImageRefResult = CommandResult(EdsCreateEvfImageRef(streamRef, &imageRef))
        if createImageRefResult.isError() {
            return nil
        }
        
        let downloadImageResult = CommandResult(EdsDownloadEvfImage(_cameraRef, imageRef))
        if downloadImageResult.isError() {
            return nil
        }
        
        // Get Image Details
        var imageSize: EdsUInt64 = 0
        var pImage: UnsafeMutableRawPointer? = nil
        
        EdsGetPointer(streamRef, &pImage)
        EdsGetLength(streamRef, &imageSize)
        
        if(imageRef != nil)
        {
            EdsRelease(imageRef)
        }
        
        if(streamRef != nil)
        {
            EdsRelease(streamRef)
        }
        
        let endget = mach_absolute_time()

        if imageSize > 0 {
            let startdcom = mach_absolute_time()
            if var imgData = Frame.decompress(UnsafeMutableRawPointer(pImage)!, length: UInt(imageSize)) {
                let endcom = mach_absolute_time()
                //imgData.id = UUID().uuidString
                imgData.timestamp = starts
                imgData.sequence = _sequence
                
                _sequence += 1

                flog(imgData, "received sdk response", timestamp: endget)
                flog(imgData, "decompress start", timestamp: startdcom)
                flog(imgData, "decompress end", timestamp: endcom)
                return imgData
            }

        }
        

        return nil
    }
    
    
    @discardableResult
    private func registerEdsEventHandlers() -> Bool {
        let camera: UnsafeMutableRawPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        let result = CommandResult(EdsSetCameraStateEventHandler(_cameraRef, EdsStateEvent(kEdsStateEvent_All), edsHandleStateEvent, camera))
        if result.isError() {
            return false
        }
        return true
    }
    
    @discardableResult
    private func removeEdsEventHandlers() -> Bool {
        let result = CommandResult(EdsSetCameraStateEventHandler(_cameraRef, EdsStateEvent(kEdsStateEvent_All), nil, nil))
        if result.isError() {
            return false
        }
        return true
    }


    
}


let edsHandleStateEvent : EdsStateEventHandler = { ( inEvent, inParam, inContext)->EdsError in

    var error = EdsError(EDS_ERR_OK)
    
    dlog("handleStateEvent \(inEvent)")
    switch(inEvent)
    {
        case EdsStateEvent(kEdsStateEvent_Shutdown):
            dlog("kEdsStateEvent_Shutdown")
            break;

        case EdsStateEvent(kEdsStateEvent_WillSoonShutDown):
            dlog("kEdsStateEvent_WillSoonShutDown")
            break;

        case EdsStateEvent(kEdsStateEvent_ShutDownTimerUpdate):
            dlog("kEdsStateEvent_ShutDownTimerUpdate")
            break;

        default:
            break;
    }
    return error;
}

extension CanonCamera {
    private func getEdsPropertyValue(_ property: CanonProperty) -> CanonProperty? {
        guard let cameraRef = _cameraRef else {
            return nil
        }
        var propertyWithValue: CanonProperty?
        let propertyID = property.id

        var propType: EdsDataType = kEdsDataType_Unknown
        var propSize: EdsUInt32 = 0
        
        let propertySizeResult = CommandResult(EdsGetPropertySize(cameraRef, propertyID, 0, &propType, &propSize))
        if propertySizeResult.isOK() {
            if(propType == kEdsDataType_UInt32 || propType == kEdsDataType_Int32 || propertyID == EdsPropertyID(kEdsPropID_Evf_OutputDevice))
            {
                var uintData: EdsUInt32 = 0
                let getPropertyResult = CommandResult(EdsGetPropertyData(cameraRef, propertyID, 0, EdsUInt32(MemoryLayout<EdsUInt32>.size), &uintData))
                
                if getPropertyResult.isOK() {
                    propertyWithValue = property.withValue(uintData)
                }
            }
            else if(propType == kEdsDataType_String)
            {
                var stringData:[EdsChar] = Array<EdsChar>(repeating: 0, count: 256)
                
                let getPropertyResult = CommandResult(EdsGetPropertyData(cameraRef, propertyID, 0, EdsUInt32(MemoryLayout<EdsChar>.size*256), &stringData))
                if getPropertyResult.isOK() {
                    let propertyStringValue : String = String(cString: stringData,encoding: String.Encoding.ascii)!
                    propertyWithValue = property.withValue(propertyStringValue)
                }
            }
        }
        return propertyWithValue
    }
}

extension CanonCamera {
    static func setup() {
        var result = CommandResult(EdsInitializeSDK())
        if result.isError() {
            dlog("Error creating SDK connection: \(result)")
        }
        
        result = CommandResult(EdsSetCameraAddedHandler(edsHandleCameraAddEvent, nil))
        if result.isError() {
            dlog("Error adding Camera Added Handler: \(result)")
        }
    }
    static func teardown() {
        
        var result = CommandResult(EdsSetCameraAddedHandler(nil, nil))
        if result.isError() {
            dlog("Error removing Camera Added Handler: \(result)")
        }
        
        result = CommandResult(EdsTerminateSDK())
        if result.isError() {
            dlog("Error terminating SDK connection: \(result)")
        }
    }
    
    static func loadCameras() {
        DispatchQueue.main.async {
            var cameraList = nil as EdsCameraListRef?
            var result = CommandResult()
            result = CommandResult(EdsGetCameraList(&cameraList))
            if result.isError() {
                return //nil
            }
            var cameraCount = 0 as EdsUInt32
            result = CommandResult(EdsGetChildCount(cameraList, &cameraCount))
            if result.isError() {
                if cameraList != nil {
                    EdsRelease(cameraList)
                }
                return //nil
            }

            var availableCameras: [CanonCamera] = []
            for i in 0..<cameraCount {
                
                var cameraRef: EdsCameraRef? = nil
                var deviceInfo: EdsDeviceInfo = EdsDeviceInfo()
                
                let cameraResult = CommandResult(EdsGetChildAtIndex(cameraList, EdsInt32(i), &cameraRef))

                if cameraResult.isOK() {
                    
                    guard let cameraRef = cameraRef else {
                        continue
                    }
                    
                    let deviceResult = CommandResult(EdsGetDeviceInfo(cameraRef, &deviceInfo))

                    if deviceResult.isOK() {
                        let edsCamera = CanonCamera(cameraRef: cameraRef, deviceInfo: deviceInfo)
                        availableCameras.append(edsCamera)
                        
                    }
                }
            }
            if cameraList != nil {
                EdsRelease(cameraList)
            }
            dlog("availableCameras \(availableCameras)")
            
            NotificationCenter.default.post(name: .cameraAddedEvent, object: nil, userInfo: ["Cameras": availableCameras])

        }

        //return availableCameras
    }
}

let edsHandleCameraAddEvent : EdsCameraAddedHandler = { ( inContext ) -> EdsError in

    var error = EdsError(EDS_ERR_OK)
    
    dlog("Camera added..")
    Thread.sleep(forTimeInterval:0.1)
    CanonCamera.loadCameras()

    return error;
}

