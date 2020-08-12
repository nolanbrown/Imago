//
//  Stream.swift
//  SimpleDALPlugin
//
//  Created by 池上涼平 on 2020/04/25.
//  Copyright © 2020 com.seanchas116. All rights reserved.
//

import Foundation
import CoreImage


class Stream: Object {
    var objectID: CMIOObjectID = 0
    let name = PLUGIN_STREAM_NAME
    let width = 1280
    let height = 720
    private var _sequenceNumber: UInt64 = 0

    private var frameRate = 30

    private var queueAlteredProc: CMIODeviceStreamQueueAlteredProc?
    private var queueAlteredRefCon: UnsafeMutableRawPointer?
    
    private var _imagoStream: ImagoStream
    private lazy var _context: CIContext = {
        return CIContext()
    }()

    private lazy var formatDescription: CMVideoFormatDescription? = {
        var formatDescription: CMVideoFormatDescription?
        let error = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32ARGB,
            width: Int32(width), height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            dlog("CMVideoFormatDescriptionCreate Error: \(error)")
            return nil
        }
        return formatDescription
    }()

    private lazy var clock: CFTypeRef? = {
        var clock: Unmanaged<CFTypeRef>? = nil

        let error = CMIOStreamClockCreate(
            kCFAllocatorDefault,
            "\(name) clock" as CFString,
            Unmanaged.passUnretained(self).toOpaque(),
            CMTimeMake(value: 1, timescale: 10),
            100, 10,
            &clock);
        guard error == noErr else {
            dlog("CMIOStreamClockCreate Error: \(error)")
            return nil
        }
        return clock?.takeUnretainedValue()
    }()

    private lazy var queue: CMSimpleQueue? = {
        var queue: CMSimpleQueue?
        let error = CMSimpleQueueCreate(
            allocator: kCFAllocatorDefault,
            capacity: 30,
            queueOut: &queue)
        guard error == noErr else {
            dlog("CMSimpleQueueCreate Error: \(error)")
            return nil
        }
        return queue
    }()

    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
        kCMIOStreamPropertyFormatDescription: Property(formatDescription!),
        kCMIOStreamPropertyFormatDescriptions: Property([formatDescription!] as CFArray),
        kCMIOStreamPropertyDirection: Property(UInt32(0)),
        kCMIOStreamPropertyFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRates: Property(Float64(frameRate)),
        kCMIOStreamPropertyMinimumFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRateRanges: Property(AudioValueRange(mMinimum: Float64(frameRate), mMaximum: Float64(frameRate))),
        kCMIOStreamPropertyClock: Property(CFTypeRefWrapper(ref: clock!)),
    ]

    init() {
        _imagoStream = ImagoStream()
        frameRate = _imagoStream.framesPerSecond()
    }
    
    func start() {
        dlog("START STREAM")

        _imagoStream.receivedFrame = self.enqueueFrame
        _imagoStream.start()

    }

    func stop() {
        dlog("STOP STREAM")
        _imagoStream.stop()
        _imagoStream.receivedFrame = nil
    }

    func enqueueFrame(frame: Frame) {
        guard let queue = queue else {
            dlog("queue is nil")
            return
        }
        
        guard CMSimpleQueueGetCount(queue) < CMSimpleQueueGetCapacity(queue) else {
            dlog("queue is full")
            return
        }
        
        guard let pixelBuffer: CVPixelBuffer = frame.buildPixelBuffer(image: nil, inContext: _context) else {
            dlog("pixel buffer couldn't be created")
            return
        }

        let fps = frameRate
        let sequence = _sequenceNumber
        let scale = UInt64(fps) * 100
        let duration = CMTime(value: CMTimeValue(scale / UInt64(fps)), timescale: CMTimeScale(scale))
        let timestamp = CMTime(value: duration.value * CMTimeValue(sequence), timescale: CMTimeScale(scale))
        
         let timing: CMSampleTimingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: timestamp,
            decodeTimeStamp: timestamp
        )


        var error = noErr

        var formatDescription: CMFormatDescription?
        error = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            dlog("CMVideoFormatDescriptionCreateForImageBuffer Error: \(error)")
            return
        }
        
        error = CMIOStreamClockPostTimingEvent(timing.decodeTimeStamp, mach_absolute_time(), true, clock)
        guard error == noErr else {
            dlog("CMSimpleQueueCreate Error: \(error)")
            return
        }
        var frameTiming = timing
        var sampleBufferUnmanaged: Unmanaged<CMSampleBuffer>? = nil
        error = CMIOSampleBufferCreateForImageBuffer(
            kCFAllocatorDefault,
            pixelBuffer,
            formatDescription,
            &frameTiming,
            sequence,
            UInt32(kCMIOSampleBufferNoDiscontinuities),
            &sampleBufferUnmanaged
        )
        guard error == noErr else {
            dlog("CMIOSampleBufferCreateForImageBuffer Error: \(error)")
            return
        }

        CMSimpleQueueEnqueue(queue, element: sampleBufferUnmanaged!.toOpaque())
        queueAlteredProc?(objectID, sampleBufferUnmanaged!.toOpaque(), queueAlteredRefCon)
        _sequenceNumber += 1
    }
    
    func copyBufferQueue(queueAlteredProc: CMIODeviceStreamQueueAlteredProc?, queueAlteredRefCon: UnsafeMutableRawPointer?) -> CMSimpleQueue? {
        self.queueAlteredProc = queueAlteredProc
        self.queueAlteredRefCon = queueAlteredRefCon
        return self.queue
    }

}
