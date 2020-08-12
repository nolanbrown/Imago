//
//  CIImage+Imago.swift
//  Imago
//
//  Created by Nolan Brown on 7/29/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import CoreImage

extension CIImage {

    func toCGImage(withContext context: CIContext) -> CGImage? {
        return context.createCGImage(self, from: self.extent)
    }
    
    func toPixelBuffer(withContext context: CIContext, fromPool pool: CVPixelBufferPool? = nil) -> CVPixelBuffer? {
        let imageRect = self.extent
        let size = imageRect.size

        
        guard let pixelBuffer = CVPixelBuffer.create(withSize: size, fromPool: pool) else {
            return nil
        }

        let rect = NSMakeRect(0, 0, size.width, size.height);
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        context.render(self, to:pixelBuffer, bounds: rect, colorSpace: rgbColorSpace)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        return pixelBuffer
    }
    
    func toJpegData(_ context: CIContext? = nil) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let ctx: CIContext = context ?? CIContext()

        let options = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 1.0]

        let data = ctx.jpegRepresentation(of: self, colorSpace: colorSpace, options: options)
        return data
    }
}
