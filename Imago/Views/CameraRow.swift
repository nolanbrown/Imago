//
//  CameraRow.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import SwiftUI

struct CameraRow: View {
    @EnvironmentObject var viewController: ViewController

    @ObservedObject var camera: Camera
    @State var filter: CameraFilter = .None
        
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 6) {
                Circle()
                    .fill(camera.streaming ? Color.green : Color.red)
                    .frame(width: 9, height: 9).padding([.leading], 6.0)
                Spacer()
                VStack {

                    Text(camera.name)
                    
                    HStack {
                         if self.camera.streaming {
                            CameraFilterMenu(camera: camera)
                        } else {
                            Button(action: {
                                if self.camera.streaming {
                                    self.viewController.setActiveCamera(nil)
                                }
                                else {
                                    self.viewController.setActiveCamera(self.camera)
                                }
                                }) {
                                    Text(camera.streaming ? "Stop" : "Start")
                            }
                        }
                    }

                }
                Spacer()
                Image("CameraIcon").frame(width: 50, height: 50).padding([.trailing], 6.0)
                
            }.frame(maxWidth: .infinity).padding([.all], 6.0)

        }.background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.white)).padding([.all], 6.0).onTapGesture {
            if self.camera.streaming {
                self.viewController.setActiveCamera(nil)
            }
            else {
                self.viewController.setActiveCamera(self.camera)
            }
        }
    }
}
