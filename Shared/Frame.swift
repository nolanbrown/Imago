//
//  Frame.swift
//  Imago
//
//  Created by Nolan Brown on 7/16/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import SwiftUI


struct Frame  {
    let id: String
    let height: Int
    let width: Int
    let bytesPerRow: Int
    let pixelSize: Int
    var data: Data

    var bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    var timestamp: UInt64 = 0
    var fps: Int = 30
    var sequence: UInt64 = 0
    var isDataPixelBuffer: Bool = false

    
    init(data: Data, height: Int, width: Int, bytesPerRow: Int, pixelSize: Int, id: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.data = data
        self.height = height
        self.width = width
        self.bytesPerRow = bytesPerRow
        self.pixelSize = pixelSize
    }
    func getSize() -> CGSize {
        return CGSize(width: self.width, height: self.height)
    }
    
    func copy() -> Frame {
        var frame = Frame(data: data, height: height, width: width, bytesPerRow: bytesPerRow, pixelSize: pixelSize)
        frame.isDataPixelBuffer = isDataPixelBuffer
        frame.bitmapInfo = bitmapInfo
        frame.timestamp = timestamp
        frame.fps = fps
        frame.sequence = UInt64(sequence)
        return frame
    }
    
    func elapsedSeconds(_ ts: UInt64 = mach_absolute_time()) -> Double {
        let current_ts = self.timestamp
        var recent_ts = ts
        var past_ts = current_ts
        if recent_ts < past_ts {
            recent_ts = current_ts
            past_ts = ts
        }
        
        let diff =  TimeInterval(recent_ts - past_ts) / TimeInterval(NSEC_PER_SEC)
        let fpx = Double(fps)
        let remainer = (diff * fpx).truncatingRemainder(dividingBy: 1)
        let calcedFPS = fpx - (fpx * remainer)
        let fpsString = String(format:"%.2f",calcedFPS)
        //dlog("\(self) elapsedSeconds \(diff) \(fpsString)fps")
        return diff
    }
    
    func getTimingInfo() -> CMSampleTimingInfo {
        let scale = UInt64(fps) * 100
        let duration = CMTime(value: CMTimeValue(scale / UInt64(fps)), timescale: CMTimeScale(scale))
        let timestamp = CMTime(value: duration.value * CMTimeValue(sequence), timescale: CMTimeScale(scale))
        
        return CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: timestamp,
            decodeTimeStamp: timestamp
        )
    }
    
    func getVideoFormatDescription() -> CMVideoFormatDescription? {
        var formatDescription: CMVideoFormatDescription?
        let error = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32ARGB,
            width: Int32(width), height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription)
        if error != noErr {
            dlog("Error creating CMVideoFormatDescription \(error)")
        }
        return formatDescription
    }
    
    func hash() -> Int {
        return data.hashValue
    }
}


/*

Serialization
CFPropertyListCreateData
 
Time elapsed for serialize: 0.00884699821472168 s.
Time elapsed for create: 0.005692005157470703 s.
___________

JSONEncoder
Time elapsed for jsonserialize: 0.0524829626083374 s.
Time elapsed for jsoncreate: 0.049543023109436035 s.

 
 We need to serialize Frame information into a Data object to send to the plugin
 
*/

extension Frame {
    func serialize() -> Data? {
        let obj = [
            "id": id,
            "height": height,
            "width": width,
            "bytesPerRow": bytesPerRow,
            "pixelSize": pixelSize,
            "bitmapInfo": bitmapInfo,
            "timestamp": timestamp,
            "fps": fps,
            "sequence": sequence,
            "data": data,
            "isDataPixelBuffer": isDataPixelBuffer,
            ] as [String : Any]
        let data: Unmanaged<CFData> = CFPropertyListCreateData(kCFAllocatorDefault, obj as CFPropertyList, CFPropertyListFormat.binaryFormat_v1_0, 0, nil)
        return data.takeRetainedValue() as Data
    }
    
    static func deserialize(fromData data: Data) -> Frame? {
        var error: Unmanaged<CFError>?
        var inputFormat = CFPropertyListFormat.binaryFormat_v1_0
        let options: CFOptionFlags = 0
        guard let plist: CFPropertyList = CFPropertyListCreateWithData(kCFAllocatorDefault, data as CFData, options, &inputFormat, &error)?.takeRetainedValue()
            else {
                return nil
        }

        let id = plist["id"] as! String
        let w = plist["width"] as! Int
        let h = plist["height"] as! Int
        let bpr = plist["bytesPerRow"] as! Int
        let ps = plist["pixelSize"] as! Int
        let bi = plist["bitmapInfo"] as! UInt32
        let ts = plist["timestamp"] as! UInt64
        let fps = plist["fps"] as! Int
        let sequence = plist["sequence"] as! UInt64
        let d = plist["data"] as! Data
        let isDataPixelBuffer = plist["isDataPixelBuffer"] as! Bool

        var frame = Frame(data: d, height: h, width: w, bytesPerRow: bpr, pixelSize: ps, id: id)
        frame.isDataPixelBuffer = isDataPixelBuffer
        frame.bitmapInfo = UInt32(bi)
        frame.timestamp = UInt64(ts)
        frame.fps = fps
        frame.sequence = UInt64(sequence)
        return frame

    }
    
}


extension Frame {
    func buildCIImage() -> CIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if self.bytesPerRow == 0 {
            let bitmapImg = NSBitmapImageRep(data: data)
            if bitmapImg != nil {
                return CIImage(bitmapImageRep: bitmapImg!)
            }

        }
        else {
            return CIImage(bitmapData: data,
                           bytesPerRow: bytesPerRow,
                           size: getSize(),
                           format: CIFormat.BGRA8,
                           colorSpace: colorSpace)
            
        }
        return nil
    }

    func findFaces(_ cicontext: CIContext?, _ ciimage: CIImage?) -> CIImage? {

        var ctx = cicontext
        if ctx == nil {
            ctx = CIContext()
        }

        var ciimg = ciimage
        if ciimg == nil {
            ciimg = buildCIImage()
        }

   // create a face detector - since speed is not an issue we'll use a high accuracy
   // detector
        let detector: CIDetector! = CIDetector(ofType: CIDetectorTypeFace,
                                              context: ctx,
                                              options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector.features(in: ciimage!, options: nil)
        for faceFeature in features {
            var faceRect = faceFeature.bounds
            faceRect = CGRect(x: faceRect.minX - 30, y: faceRect.minY - 30, width: faceRect.width + 60, height: faceRect.height + 60)

            ciimg = ciimg!.cropped(to: faceRect)
            
            print("faceFeature \(faceFeature)")
            return ciimg
            
        }

        return ciimg
    }

    func buildCGContext() -> CGContext? {
        let rawBytes: UnsafeMutableRawPointer = unsafeBitCast(self.data, to: UnsafeMutableRawPointer.self)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let imageContext = CGContext(data: rawBytes,
                                           width: self.width,
                                           height: self.height,
                                           bitsPerComponent: 8,
                                           bytesPerRow: self.bytesPerRow,
                                           space: colorSpace,
                                           bitmapInfo: self.bitmapInfo,
                                           releaseCallback: nil, releaseInfo: nil) else {return nil}

        return imageContext

        //guard let cgImage = imageContext.makeImage() else {return nil}
    }

    /*
https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html#//apple_ref/doc/uid/TP30001185-CH10-SW1
     https://docs.huihoo.com/apple/wwdc/2011/session_422__using_core_image_on_ios_and_mac_os_x.pdf
     */
    func image(_ ciContext: CIContext? = nil) -> NSImage? {
        guard let img = buildCIImage() else {
            return nil
        }
        let ctx = ciContext ?? CIContext()

        if let cgImg = ctx.createCGImage(img, from: img.extent) {
            return NSImage(cgImage: cgImg, size: self.getSize())
        }
        return nil
    }
    
    func cgimage(_ ciContext: CIContext? = nil) -> CGImage? {
        guard let img = buildCIImage() else {
            return nil
        }
        let ctx = ciContext ?? CIContext()

        if let cgImg = ctx.createCGImage(img, from: img.extent) {
            return cgImg
        }
        return nil
    }


    func buildPixelBuffer(image: CIImage? = nil, inContext ciContext: CIContext? = nil) -> CVPixelBuffer? {
        
        if isDataPixelBuffer {
            return CVPixelBuffer.fromData(data, height: height, width: width)
        }
        
        guard let ciImage = image ?? buildCIImage() else {
            return nil
        }
        
        let ctx = ciContext ?? CIContext()
        return ciImage.toPixelBuffer(withContext: ctx)
    }
  
}

