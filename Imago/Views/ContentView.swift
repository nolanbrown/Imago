//
//  ContentView.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewController: ViewController

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView() {
                    ForEach(self.viewController.cameras, id: \.identifier) { camera in
                        CameraRow(camera: camera).tag(camera.identifier).padding([.all], 6.0)
                    }
                }.frame(width:geometry.size.width)

            }.onAppear {
                self.viewController.setup()
            }
        }
    }
}


