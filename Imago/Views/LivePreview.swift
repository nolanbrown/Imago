//
//  LivePreview.swift
//  Imago
//
//  Created by Nolan Brown on 8/10/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import SwiftUI

struct LivePreview: View {
    @ObservedObject var camera: Camera
    @State var expanded: Bool = false
    @State var size: NSSize = NSSize(width: 150, height: 100)
    
    var isPreviewAvailable: Bool {
        return false
        //return camera.streaming && camera.previewPixelBuffer != nil
    }
    
    func getPreviewImage() -> NSImage? {
//        if isPreviewAvailable {
//            return NSImage(cgImage: camera.previewPixelBuffer!.toImage()!, size: camera.previewPixelBuffer!.size)
//        }
        return nil
    }

    var body: some View {
        VStack {
            if isPreviewAvailable {
                Image(nsImage: self.getPreviewImage()!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:size.width, height:size.height)
                    .scaledToFit()
                    .padding([.trailing], 6.0)
            }
            else {
                Image("CameraIcon").frame(width: 50, height: 50).padding([.trailing], 6.0)
            }
        }
    }
}

