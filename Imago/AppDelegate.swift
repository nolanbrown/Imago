//
//  AppDelegate.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Cocoa
import SwiftUI


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSToolbarDelegate {

    var window: NSWindow!
    var viewController: ViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        viewController = ViewController()
        
        // Create the titlebar accessory
        let titlebarAccessoryView = TitlebarAccessory().environmentObject(viewController).frame(minWidth: 480, minHeight: 40, alignment: .topLeading).padding([.top, .leading, .trailing], -15.0).padding([.bottom, .leading],15.0)
        let accessoryHostingView = NSHostingView(rootView:titlebarAccessoryView)
        accessoryHostingView.frame.size = accessoryHostingView.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = accessoryHostingView
        
        
        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Imago"
        window.setFrameAutosaveName("Main Window")

        window.delegate = self
        window.addTitlebarAccessoryViewController(titlebarAccessory)

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView().environmentObject(viewController)

        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed \(sender)")
        return true
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("applicationWillTerminate")
        viewController.teardown()
    }

}



