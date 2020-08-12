//
//  TitlebarAccesory.swift
//  Imago
//
//  Created by Nolan Brown on 8/10/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import SwiftUI

struct TitlebarAccessory: View {
    @EnvironmentObject private var viewController: ViewController

    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                self.viewController.loadCameras()
                }) {
                    Text("Load Cameras")
            }
            

        }.frame(minHeight: 30, maxHeight: 30)

    }
}
