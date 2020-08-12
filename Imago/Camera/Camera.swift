//
//  Camera.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//

import SwiftUI

import Foundation
import Cocoa
/*
 
 The Camera class is expected to be subclassed to interface with a particular brand or type of camera and return frames
 */

extension Notification.Name {
    static let didLoadCameras = Notification.Name("didLoadCameras")
    static let cameraAddedEvent = Notification.Name("cameraAddedEvent")
}

class Camera : Hashable, Identifiable, ObservableObject, CustomDebugStringConvertible {
    var currentFrame: Frame?
    
    // For furture use when we can save previously used Cameras
    // Stores if a camera is connected to the applications
    @Published var connected: Bool = true
    
    // Is the camera sending frames?
    @Published var streaming: Bool = false
    
    var name: String = "Camera"
    var model: String = "Model"
    var identifier: String = "Serial Number"

    var isActive: Bool = false
    
    var filter: CameraFilter = CameraFilter.None
    
    
    var debugDescription: String {
        return "\(String(describing: type(of: self)))(id:\(identifier) name:'\(name)')"
    }

    var didReceiveFrame: ((Frame, Camera)->Void)?

    
    //var model: String
    static func == (lhs: Camera, rhs: Camera) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self).hashValue)
    }

    
    func setActive(active: Bool) {
        if active == true {
            streaming = true
        }
        else if active == false {
            streaming = false
        }
        isActive = active
    }
    
     
    func setFrame(_ frame: Frame) {
        if self.isActive {

            DispatchQueue.main.async { [unowned self, frame] in
                self.currentFrame = frame
                //self.previewImage = image

                self.didReceiveFrame?(frame, self)
            }

        }
    }

}


