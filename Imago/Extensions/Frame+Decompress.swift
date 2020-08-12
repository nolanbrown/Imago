//
//  Frame+Decompress.swift
//  Imago
//
//  Created by Nolan Brown on 7/19/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

func TJPAD(_ width: Int32) -> Int32 {
    return (((width) + 3) & (~3))
}

extension Frame {

    static func decompress(_ bytes: UnsafeMutableRawPointer?, length: UInt) -> Frame? {
        let _decompressor: tjhandle = tjInitDecompress()
        var width: Int32 = 0
        var height: Int32 = 0

        let rawBytes: UnsafeMutablePointer<UInt8> = bytes!.assumingMemoryBound(to: UInt8.self)
        let result = tjDecompressHeader(_decompressor,
                                        rawBytes,
                                        length,
                                        &width, &height)
        if result == 0 {
            
            let encoding = TJPF_BGRA.rawValue
            
            // We can't access tjPixelSize directly because it lacks a type in turbojpeg and becomes a tuple in Swift
            var tjPixelSizes = tjPixelSize
            let pixelSize = withUnsafeBytes(of: &tjPixelSizes) { (rawPtr) -> Int32 in
                let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: Int32.self)
                return ptr[Int(encoding)]
            }
            let wanted_bpr = TJPAD(pixelSize * width)
            
            let bufferSize = Int(wanted_bpr * height)
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            let result = tjDecompress2(_decompressor, rawBytes, length, buffer, width, wanted_bpr, height, encoding, 0);
            
            // Use TJFLAG_BOTTOMUP when rendering in PreviewMetalView
            //let result = tjDecompress2(_decompressor, rawBytes, length, buffer, width, wanted_bpr, height, TJPF_BGRA.rawValue, TJFLAG_BOTTOMUP);

            if (result == 0)
            {
                let data = Data(bytes: buffer, count: bufferSize)
                
                let imgData = Frame(data:data,
                                        height: Int(height),
                                        width: Int(width),
                                        bytesPerRow: Int(wanted_bpr),
                                        pixelSize: Int(pixelSize))
                
                free(buffer)
                tjDestroy(_decompressor)
                return imgData
            }
        }
        tjDestroy(_decompressor)

        return nil
    }
}
