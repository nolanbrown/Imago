//
//  PluginInterface.swift
//  SimpleDALPlugin
//
//  Created by 池上涼平 on 2020/04/25.
//  Copyright © 2020 com.seanchas116. All rights reserved.
//

import Foundation

private func QueryInterface(plugin: UnsafeMutableRawPointer?, uuid: REFIID, interface: UnsafeMutablePointer<LPVOID?>?) -> HRESULT {
    //dlog()
    let pluginRefPtr = UnsafeMutablePointer<CMIOHardwarePlugInRef?>(OpaquePointer(interface))
    pluginRefPtr?.pointee = pluginRef
    return HRESULT(noErr)
}

private func AddRef(plugin: UnsafeMutableRawPointer?) -> ULONG {
    //dlog()
    return 0
}

private func Release(plugin: UnsafeMutableRawPointer?) -> ULONG {
    //dlog()
    return 0
}

private func Initialize(plugin: CMIOHardwarePlugInRef?) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func InitializeWithObjectID(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID) -> OSStatus {
    //dlog()
    guard let plugin = plugin else {
        return OSStatus(kCMIOHardwareIllegalOperationError)
    }

    var error = noErr

    let pluginObject = Plugin()
    pluginObject.objectID = objectID
    addObject(object: pluginObject)

    let device = Device()
    error = CMIOObjectCreate(plugin, CMIOObjectID(kCMIOObjectSystemObject), CMIOClassID(kCMIODeviceClassID), &device.objectID)
    guard error == noErr else {
        dlog("error: \(error)")
        return error
    }
    addObject(object: device)

    let stream = Stream()
    error = CMIOObjectCreate(plugin, device.objectID, CMIOClassID(kCMIOStreamClassID), &stream.objectID)
    guard error == noErr else {
        dlog("error: \(error)")
        return error
    }
    addObject(object: stream)

    device.streamID = stream.objectID

    error = CMIOObjectsPublishedAndDied(plugin, CMIOObjectID(kCMIOObjectSystemObject), 1, &device.objectID, 0, nil)
    guard error == noErr else {
        dlog("error: \(error)")
        return error
    }

    error = CMIOObjectsPublishedAndDied(plugin, device.objectID, 1, &stream.objectID, 0, nil)
    guard error == noErr else {
        dlog("error: \(error)")
        return error
    }

    return noErr
}
private func Teardown(plugin: CMIOHardwarePlugInRef?) -> OSStatus {
    //dlog()
    return noErr
}
private func ObjectShow(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID) {
    //dlog()
}

private func ObjectHasProperty(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?) -> DarwinBoolean {
    //dlog(address?.pointee.mSelector)
    guard let address = address?.pointee else {
        dlog("Address is nil")
        return false
    }
    guard let object = objects[objectID] else {
        dlog("Object not found")
        return false
    }
    return DarwinBoolean(object.hasProperty(address: address))
}

private func ObjectIsPropertySettable(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, isSettable: UnsafeMutablePointer<DarwinBoolean>?) -> OSStatus {
    //dlog(address?.pointee.mSelector)
    guard let address = address?.pointee else {
        dlog("Address is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let object = objects[objectID] else {
        dlog("Object not found")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    let settable = object.isPropertySettable(address: address)
    isSettable?.pointee = DarwinBoolean(settable)
    return noErr
}

private func ObjectGetPropertyDataSize(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UnsafeMutablePointer<UInt32>?) -> OSStatus {
    //dlog(address?.pointee.mSelector)
    guard let address = address?.pointee else {
        dlog("Address is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let object = objects[objectID] else {
        dlog("Object not found")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    dataSize?.pointee = object.getPropertyDataSize(address: address)
    return noErr
}

private func ObjectGetPropertyData(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UInt32, dataUsed: UnsafeMutablePointer<UInt32>?, data: UnsafeMutableRawPointer?) -> OSStatus {
    //dlog(address?.pointee.mSelector)
    guard let address = address?.pointee else {
        dlog("Address is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let object = objects[objectID] else {
        dlog("Object not found")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let data = data else {
        dlog("data is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    var dataUsed_: UInt32 = 0
    object.getPropertyData(address: address, dataSize: &dataUsed_, data: data)
    dataUsed?.pointee = dataUsed_
    return noErr
}

private func ObjectSetPropertyData(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UInt32, data: UnsafeRawPointer?) -> OSStatus {
    //dlog()

    guard let address = address?.pointee else {
        dlog("Address is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let object = objects[objectID] else {
        dlog("Object not found")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let data = data else {
        dlog("data is nil")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    object.setPropertyData(address: address, data: data)
    return noErr
}

private func DeviceSuspend(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID) -> OSStatus {
    //dlog()
    return noErr
}

private func DeviceResume(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID) -> OSStatus {
    //dlog()
    return noErr
}

private func DeviceStartStream(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, streamID: CMIOStreamID) -> OSStatus {
    //dlog()
    guard let stream = objects[streamID] as? Stream else {
        dlog("no stream")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    stream.start()
    return noErr
}

private func DeviceStopStream(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, streamID: CMIOStreamID) -> OSStatus {
    //dlog()
    guard let stream = objects[streamID] as? Stream else {
        dlog("no stream")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    stream.stop()
    return noErr
}

private func DeviceProcessAVCCommand(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, avcCommand: UnsafeMutablePointer<CMIODeviceAVCCommand>?) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func DeviceProcessRS422Command(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, rs422Command: UnsafeMutablePointer<CMIODeviceRS422Command>?) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func StreamCopyBufferQueue(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID, queueAlteredProc: CMIODeviceStreamQueueAlteredProc?, queueAlteredRefCon: UnsafeMutableRawPointer?, queueOut: UnsafeMutablePointer<Unmanaged<CMSimpleQueue>?>?) -> OSStatus {
    //dlog()
    guard let queueOut = queueOut else {
        dlog("no queueOut")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let stream = objects[streamID] as? Stream else {
        dlog("no stream")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    guard let queue = stream.copyBufferQueue(queueAlteredProc: queueAlteredProc, queueAlteredRefCon: queueAlteredRefCon) else {
        dlog("no queue")
        return OSStatus(kCMIOHardwareBadObjectError)
    }
    queueOut.pointee = Unmanaged<CMSimpleQueue>.passRetained(queue)
    return noErr
}

private func StreamDeckPlay(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func StreamDeckStop(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func StreamDeckJog(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID, speed: Int32) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func StreamDeckCueTo(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID, requestedTimecode: Float64, playOnCue: DarwinBoolean) -> OSStatus {
    //dlog()
    return OSStatus(kCMIOHardwareIllegalOperationError)
}

private func createPluginInterface() -> CMIOHardwarePlugInInterface {
    return CMIOHardwarePlugInInterface(
        _reserved: nil,
        QueryInterface: QueryInterface,
        AddRef: AddRef,
        Release: Release,
        Initialize: Initialize,
        InitializeWithObjectID: InitializeWithObjectID,
        Teardown: Teardown,
        ObjectShow: ObjectShow,
        ObjectHasProperty: ObjectHasProperty,
        ObjectIsPropertySettable: ObjectIsPropertySettable,
        ObjectGetPropertyDataSize: ObjectGetPropertyDataSize,
        ObjectGetPropertyData: ObjectGetPropertyData,
        ObjectSetPropertyData: ObjectSetPropertyData,
        DeviceSuspend: DeviceSuspend,
        DeviceResume: DeviceResume,
        DeviceStartStream: DeviceStartStream,
        DeviceStopStream: DeviceStopStream,
        DeviceProcessAVCCommand: DeviceProcessAVCCommand,
        DeviceProcessRS422Command: DeviceProcessRS422Command,
        StreamCopyBufferQueue: StreamCopyBufferQueue,
        StreamDeckPlay: StreamDeckPlay,
        StreamDeckStop: StreamDeckStop,
        StreamDeckJog: StreamDeckJog,
        StreamDeckCueTo: StreamDeckCueTo)
}

let pluginRef: CMIOHardwarePlugInRef = {
    let interfacePtr = UnsafeMutablePointer<CMIOHardwarePlugInInterface>.allocate(capacity: 1)
    interfacePtr.pointee = createPluginInterface()

    let pluginRef = CMIOHardwarePlugInRef.allocate(capacity: 1)
    pluginRef.pointee = interfacePtr
    return pluginRef
}()
