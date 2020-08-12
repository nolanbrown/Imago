//
//  CameraFilter.swift
//  Imago
//
//  Created by Nolan Brown on 8/7/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreImage

struct CameraFilter: OptionSet, Hashable, CustomStringConvertible {
    static let Options: [CameraFilter] = [.Mirror, .Pixellate, .Thermalize]

    static let Mirror = CameraFilter(rawValue: 1 << 0)
    static let Pixellate = CameraFilter(rawValue: 1 << 1)
    static let Thermalize = CameraFilter(rawValue: 1 << 2)
    
    static let None = CameraFilter([])
    
    let rawValue: Int

    
    var hashValue: Int {
        return self.rawValue
    }
    

    
    static var debugDescriptions: [CameraFilter:String] = {
        var descriptions = [CameraFilter:String]()
        descriptions[.None] = "--"
        descriptions[.Mirror] = "Mirror"
        descriptions[.Pixellate] = "Pixellate"
        descriptions[.Thermalize] = "Thermalize"
        return descriptions
    }()
    
    public var keyDescriptions: String {
        var result = [String]()
        for key in CameraFilter.debugDescriptions.keys {
            guard self.contains(key),
                let description = CameraFilter.debugDescriptions[key]
                else { continue }
            result.append(description)
        }
        return "\(result)"
    }
    
    public var description: String {
        return "CameraFilter(rawValue: \(self.rawValue)) \(self.keyDescriptions)"
    }
    
    public func processImage(_ image: CIImage) -> CIImage {
        var processedImage: CIImage = image
        
        if self.contains(.Pixellate) {
            if let newImage = processedImage.pixellate(scale: 15) {
                processedImage = newImage
            }
        }
        if self.contains(.Thermalize)  {
            if let newImage = processedImage.thermalize() {
                processedImage = newImage
            }
        }
        if self.contains(.Mirror) {
            if let newImage = processedImage.mirror() {
                processedImage = newImage
            }
            
        }
        return processedImage
    }
    
    
}
