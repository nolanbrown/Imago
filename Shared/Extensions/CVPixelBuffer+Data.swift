//
//  CVPixelBuffer+Data.swift
//  Imago
//
//  Created by Nolan Brown on 7/29/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import VideoToolbox


extension CVPixelBuffer {
    
    var width: Int {
        return CVPixelBufferGetWidth(self)
    }
    var height: Int {
        return CVPixelBufferGetHeight(self)
    }
    
    var size: NSSize {
        return NSSize(width: self.width, height: self.height)
    }
    
    func toImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        
        return cgImage
    }
    
    func toData() -> Data? {
        CVPixelBufferLockBaseAddress(self,.readOnly)

        let bufferSize = CVPixelBufferGetDataSize(self)

        // UnsafeMutableRawPointer
        guard let baseAddress = CVPixelBufferGetBaseAddress(self) else {
            return nil
        }

        //let data = Data(bytesNoCopy: baseAddress, count: bufferSize, deallocator: .free)
        let data = Data(bytes: baseAddress, count: bufferSize)

        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        return data
    }

    static func fromData(_ data: Data, height: Int, width: Int) -> CVPixelBuffer? {
        
        // Create an empty pixel buffer
        var _pixelBuffer: CVPixelBuffer?
        var err = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &_pixelBuffer)
        
        guard let pixelBuffer = _pixelBuffer else {return nil}
        
        // Generate the video format description from that pixel buffer
        var format: CMFormatDescription?
        err = CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &format)
        if (err != noErr) {
            dlog("CMVideoFormatDescriptionCreateForImageBuffer err \(err)")
            return nil
        }

        // Copy memory into the pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        let srcBytesPerRow = width * 2
        
        data.withUnsafeBytes { rawBufferPointer in
            let rawPtr = rawBufferPointer.baseAddress!

            memcpy(baseAddress, rawPtr, data.count)

        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, []);
        return pixelBuffer
    }


    static func create(withSize size:NSSize, fromPool pool: CVPixelBufferPool? = nil, attributes: [String:Any]? = nil, pixelFormat: OSType = DEFAULT_PIXEL_FORMAT) -> CVPixelBuffer? {

        var attrs = attributes
        if attrs == nil {
            attrs = CVPixelBuffer.defaultAttributes(additionalAttributes: attributes, size: size, pixelFormat: pixelFormat)
            
        }
        
        var pixelBuffer : CVPixelBuffer?
        var status: CVReturn
        
        if pool != nil {
            status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool!, &pixelBuffer)
        }
        else {
            status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), pixelFormat, attrs! as CFDictionary, &pixelBuffer)
        }
        
        if status != kCVReturnSuccess {
            dlog("Failed to create CVPixelBuffer: \(status)")
        }
        
        return pixelBuffer
    }
    
    
    static func defaultAttributes(additionalAttributes: [String:Any]? = nil, size: NSSize? = nil, pixelFormat: OSType = DEFAULT_PIXEL_FORMAT) -> Dictionary<String,Any> {
        var attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
            kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue!,
            //kCVPixelBufferMetalCompatibilityKey as String:  kCFBooleanTrue!
        ]
        
        if size != nil {
            attributes[kCVPixelBufferWidthKey as String] = Int(size!.width)
            attributes[kCVPixelBufferHeightKey as String] = Int(size!.height)
        }
        if additionalAttributes != nil {
            attributes.merge(additionalAttributes!) { (_, new) in new }
        }

        return attributes
    }
    
}
