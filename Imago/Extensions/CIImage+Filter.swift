//
//  CIImage+Filter.swift
//  Imago
//
//  Created by Nolan Brown on 8/10/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreImage

// Filter conviences
extension CIImage {
    func mirror() -> CIImage? {
        return self.oriented(.upMirrored)
    }
    
    func pixellate(scale: Int = 15 ) -> CIImage? {
        if let currentFilter = CIFilter(name: "CIPixellate") {
            currentFilter.setValue(self, forKey: kCIInputImageKey)
            currentFilter.setValue(scale, forKey: kCIInputScaleKey)
            
            let v = self.centerVector()
            currentFilter.setValue(v, forKey: kCIInputCenterKey)
            
            return currentFilter.outputImage
        }
        return nil
    }
    
    func thermalize() -> CIImage? {
        if let currentFilter = CIFilter(name: "CIThermal") {
            currentFilter.setValue(self, forKey: kCIInputImageKey)
            return currentFilter.outputImage
        }
        return nil
    }
    
    
    func findFaceRects(_ context: CIContext, padding: Float = 30 ) -> [CGRect] {
        let detector: CIDetector! = CIDetector(ofType: CIDetectorTypeFace,
                                              context: context,
                                              options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector.features(in: self, options: nil)
        
        var faces : [CGRect] = []
        for faceFeature in features {
            var faceRect = faceFeature.bounds
            faceRect = faceRect.insetBy(dx: CGFloat(padding) , dy: CGFloat(padding))
            faces.append(faceRect)
            
        }

        return faces
    }
    
    func centerVector() -> CIVector {
        return CIVector(cgPoint: CGPoint(x: self.extent.width/2, y: self.extent.height / 2) )
        
    }
}

