//
//  CallerID.swift
//  Imago
//
//  Created by Nolan Brown on 7/21/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

enum CallerID: Int32 {
    case Register = 0x1
    case Deregister = 0x2
    case RegistrationConfirmation = 0x3
    case GetFrame = 0x4
    case ReceiveFrame = 0x5
    case Ping = 0x6
    case ReceiveData = 0x7
    case KillServer = 0x99
}

enum ResponseCode: Int8 {
    case OK = 0x1
    case Success = 0x2
    case NotAvailable = 0x3
    case ConnectionClosed = 0x4
    
    func data() -> Data {
        var theData : Int8 = self.rawValue
        return Data(bytes: &theData, count: 1)
    }
}



struct Response {
    enum Code: UInt8 {
        case OK = 1
        case Success = 2
        case NotAvailable = 3
        case ConnectionClosed = 4
        case Unknown = 99

        func data() -> Data {
            var theData : UInt8 = self.rawValue
            return Data(bytes: &theData, count: 1)
        }
    }

    var code: Code = .Unknown
    
    let callerID: CallerID
    let status: Int32
    let data: Data?

    init(callerID: CallerID, status: Int32, data: Data?) {
        self.callerID = callerID
        self.status = status
        self.data = data
        
        if self.data?.count == 1 {
            self.code = Code(rawValue: self.data![0]) ?? Code.Unknown
        }
        
    }
    
    func asString() -> String? {
        if data != nil {
            return String(data: data!, encoding: .utf8)
        }
        return nil
    }
    func statusString() -> String {
        switch status {
            case kCFMessagePortSuccess:
                return "CFMessagePortSuccess"
            case kCFMessagePortSendTimeout:
                return "CFMessagePortSendTimeout"
            case kCFMessagePortReceiveTimeout:
                return "CFMessagePortReceiveTimeout"
            case kCFMessagePortIsInvalid:
                return "CFMessagePortIsInvalid"
            case kCFMessagePortTransportError:
                return "CFMessagePortTransportError"
            case kCFMessagePortBecameInvalidError:
                return "CFMessagePortBecameInvalidError"
        default:
            return "Unknown Status"
        }
    }
    
    func isSuccess() -> Bool {
        switch status {
            case kCFMessagePortSuccess:
                return true
            default:
                return false
        }
    }
    
    func isTimeoutError() -> Bool {
        switch status {
        case kCFMessagePortSendTimeout, kCFMessagePortReceiveTimeout:
            return true
        default:
            return false
        }
    }
    
    func isInvalidPortError() -> Bool {
        switch status {
            case kCFMessagePortIsInvalid, kCFMessagePortBecameInvalidError:
                return true
            default:
                return false
        }
    }
}

struct Request {
    let port: CFMessagePort
    let callerID: CallerID
    let data: Data?
    let str: String?
    
    init(port: CFMessagePort, callerID: CallerID, data: Data? = nil, str: String? = nil) {
        self.port = port
        self.callerID = callerID
        self.data = data
        self.str = str
    }
    
    func messageID() -> Int32 {
        return callerID.rawValue
    }
    
    func asCFData() -> CFData? {
        var requestData: CFData? = nil
        if str != nil {
            requestData = str!.data(using: .utf8)! as CFData

        }
        else if data != nil {
            requestData = data! as CFData
        }
        return requestData
    }
}
