//
//  CVPixelBufferPool+Imago.swift
//  Imago
//
//  Created by Nolan Brown on 8/10/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

extension CVPixelBufferPool {
    static func create(size: NSSize) -> CVPixelBufferPool? {
        
        let outputPixelBufferAttributes = CVPixelBuffer.defaultAttributes(additionalAttributes: nil, size: size, pixelFormat: DEFAULT_PIXEL_FORMAT)
        
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: 5]
        var cvPixelBufferPool: CVPixelBufferPool?
        // Create a pixel buffer pool with the same pixel attributes as the input format description
        CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                poolAttributes as NSDictionary?,
                                outputPixelBufferAttributes as NSDictionary?,
                                &cvPixelBufferPool)
        return cvPixelBufferPool
    }
}
