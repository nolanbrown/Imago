//
//  Stream.swift
//  Imago
//
//  Created by Nolan Brown on 7/29/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreImage
import AppKit

enum StreamSetting {
    case Pixellate
    case Thermalize
    
}

// Coordinates frames to a registered plugin and any rendering that's required
class Stream : Hashable, Identifiable, ObservableObject {
    
    
    var name: String?
    var id: String = UUID().uuidString
    var settings: [StreamSetting] = []

    
    private var _pubsub: PubSub = PubSub(publisherPortName:IMAGO_SERVER_NAME)
    
    private var _activeCamera: Camera?
    
    private var _context: CIContext = CIContext()
    private var _bufferPool: CVPixelBufferPool?
    
    private var _fps: Int = 30

    private var _frameQueue: [Frame] = []
    
    
    fileprivate var _processingQueue: DispatchQueue  = DispatchQueue(label: "com.Imago.Camera", qos: .userInteractive) 

    
    static func == (lhs: Stream, rhs: Stream) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    
    func getPubSubMetrics() -> Dictionary<String, Any> {
        
        var metrics: [String: Any] = _pubsub.getSubscriberMetrics()
        metrics["IsRunning"] = _pubsub.isRunning()
        return metrics
        
    }
    
    func start() {
        _pubsub.start()
    }
    
    func stop() {
        _pubsub.stop()
        if _bufferPool != nil {
            CVPixelBufferPoolFlush(_bufferPool!, [])
        }
    }

    // Use frames from this camera to publish
    func makeCameraActive(_ camera: Camera?) {
        if camera != nil {
            _activeCamera?.setActive(active: false)
            camera!.didReceiveFrame = self.didReceiveFrame
            camera!.setActive(active: true)
            _activeCamera = camera
        }
        else {
            _activeCamera?.setActive(active: false)
            _activeCamera = nil
        }
        
    }
    
    /*
     Callback from the active Camera containing the latest Frame
     We process the frame before publishing to any registered subscribers
     */
    func didReceiveFrame(_ frame: Frame, _ camera: Camera) {
        _processingQueue.async { [unowned self, frame, camera] in
            if let newFrame = self.prepareFrameForPublication(frame, camera) {
                if let data = newFrame.serialize() {
                    self._pubsub.publishFrameData(data)
                }
            }
        }
    }
    
    func getCachedPixelBufferPool(_ frame: Frame) -> CVPixelBufferPool? {
        if _bufferPool != nil {
            return _bufferPool
        }
        _bufferPool = CVPixelBufferPool.create(size: frame.getSize())
        return _bufferPool
    }
    
    
    /*
     We will perform any neccessary processing to prepare the frame for publication to subscribers
     Frame's provided as input haven't had their data converted to a CVPixelBuffer yet
     
     */
    func prepareFrameForPublication(_ frame: Frame, _ camera: Camera) -> Frame? {
        var createdFrame: Frame?
        let pixelBufferPool = getCachedPixelBufferPool(frame)

        autoreleasepool {
            if let ciImage = frame.buildCIImage() {

                let processedImage = camera.filter.processImage(ciImage)
                
                
                if let pixelBuffer = processedImage.toPixelBuffer(withContext: _context, fromPool: pixelBufferPool) {

                    if let data = pixelBuffer.toData() {
                        var newFrame = frame.copy()
                        newFrame.data = data
                        newFrame.isDataPixelBuffer = true
                        createdFrame = newFrame
                    }
                }
            }

        }
        return createdFrame
    }
    
}
