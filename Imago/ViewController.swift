//
//  ViewController.swift
//  Imago
//
//  Created by Nolan Brown on 7/29/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import IOKit.pwr_mgt

/*
Manages available cameras and links them to a Stream.
*/
class ViewController: NSObject, ObservableObject, NSWindowDelegate {
    @Published var cameras: [Camera] = []
        
    private var _activeStream: Stream

    var newFrameHandler : ((Frame) -> Void)? = nil

    override init() {
        _activeStream = Stream()
        super.init()
        
        _activeStream.start()

        NotificationCenter.default.addObserver(self, selector: #selector(onCameraAddedEvent(_:)), name: .cameraAddedEvent, object: nil)
        _disableSleep()
    }

    
    deinit {
        self.teardown()
    }
    
    /*
     Action for UI
     */
    func loadCameras() -> Void {
        CanonCamera.loadCameras()
    }

    
    /*
     Called from the UI onAppear to do initial setup
     */
    func setup() {
        CanonCamera.setup()
        Thread.sleep(forTimeInterval: 0.5)
        self.loadCameras()
    }
    
    /*
     Called when closing the application
     */
    func teardown() {
        setActiveCamera(nil)
        CanonCamera.teardown()
    }
    
    func setActiveCamera(_ camera: Camera?) {
        if camera != nil {
            _activeStream.makeCameraActive(camera!)
        }
        else {
            _activeStream.makeCameraActive(nil)
        }
    }
    
    
    private func _addNewCameras(_ newCameras: [Camera]) {
        var cameraSet = Set(self.cameras)
        for cam in newCameras {
            if !cameraSet.contains(cam) {
                cameraSet.insert(cam)
            }
        }
        self.cameras = Array(cameraSet)
        self.cameras.sort { (c1, c2) -> Bool in
            if c1.name > c2.name {
                return true
            }
            return false
        }
        
    }
    
    
    private func _disableSleep() {
        var noSleepAssertion: IOPMAssertionID = IOPMAssertionID(0)
        if (noSleepAssertion == 0)
        {
            let reasonForActivity = "Imago maintaining connection to camera" as CFString

            _ = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString?,
                                            IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                            reasonForActivity, &noSleepAssertion)
        }
        
    }
    
    @objc func onCameraAddedEvent(_ notification: Notification)
    {
        if let cameras = notification.userInfo?["Cameras"] as? [Camera] {
            self._addNewCameras(cameras)
        }
    }
}

/*
extension ViewController {
    
    fileprivate var _isLiveViewActive = false
    fileprivate var _liveViewWindow : NSWindow?
        
    func showLiveViewWindow(_ camera: Camera) {
        
        if self.activeCamera != nil && self._liveViewWindow == nil {

            self._liveViewWindow = NSWindow(
                contentRect: NSRect(x:  300, y: 300, width: 300, height: 300),
                styleMask: [.titled, .closable, .miniaturizable], // .resizable, .fullSizeContentView
                backing: .buffered, defer: false)
            let view = LiveImageView(containerWindow: _liveViewWindow, camera:self.activeCamera!)
            let hostingView = NSHostingView(rootView: view)
            self._liveViewWindow!.center()
            self._liveViewWindow!.contentView = hostingView
            self._liveViewWindow!.delegate = self
            self._liveViewWindow!.makeKeyAndOrderFront(nil)
            self._isLiveViewActive = true
            self.startLiveStream()
        }
    }
    func windowWillClose(_ notification: Notification) {
        self._isLiveViewActive = false
        //self.activeCamera!.stopLiveStream()
    }
}
*/

/*
 For future use to manage application settings
 */
struct Settings : Codable {
    var showPreviewFrame: Bool
    var autoConnectToLastUsedCamera: Bool
    
    private enum CodingKeys: String, CodingKey {
      case showPreviewFrame
      case autoConnectToLastUsedCamera
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        showPreviewFrame = try values.decode(Bool.self, forKey: .showPreviewFrame)
        autoConnectToLastUsedCamera = try values.decode(Bool.self, forKey: .autoConnectToLastUsedCamera)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showPreviewFrame, forKey: .showPreviewFrame)
        try container.encode(autoConnectToLastUsedCamera, forKey: .autoConnectToLastUsedCamera)
    }
    
//    func save() {
//        let encoder = PropertyListEncoder()
//        encoder.outputFormat = .xml
//        do {
//          let data = try encoder.encode(someSettings)
//          try data.write(to: settingsURL)
//        } catch {
//          // Handle error
//          print(error)
//        }
//    }
}
