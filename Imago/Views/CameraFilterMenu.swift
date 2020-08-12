//
//  CameraFilterMenu.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation
import SwiftUI

struct CameraFilterMenu: View {
    var camera: Camera
    @State var filter: CameraFilter = .None
    
    func toggleFilter(_ newFilter: CameraFilter) {
        if newFilter == .None {
            self.filter = .None
        }
        else {
            if self.filter.contains(newFilter) {
                self.filter.remove(newFilter)
            }
            else {
                self.filter.insert(newFilter)
            }
        }

        self.camera.filter = self.filter
    }
    
    func filterName(_ filter: CameraFilter) -> String {
        var filterName = CameraFilter.debugDescriptions[filter] ?? "--"
        let checkbox = "✓"
        if self.filter.contains(filter) {
            filterName = "\(checkbox) \(filterName)"
        }
        return filterName
    }
    
    
    var body: some View {
        MenuButton("Filter") {
            ForEach(CameraFilter.Options, id: \.hashValue) { f in
                Button(self.filterName(f)) { self.toggleFilter(f) }
            }
        }.buttonStyle(DetectHover())
    }
}

/*
 From https://stackoverflow.com/questions/59837991/how-to-get-accentcolor-background-for-menu-items-in-swiftui-with-reduced-transpa
 */
struct DetectHover: ButtonStyle {
    @State private var hovering: Bool = false

    public func makeBody(configuration: DetectHover.Configuration) -> some View {
        configuration.label
            .foregroundColor(self.hovering ? Color.white : Color.primary)
            .background(self.hovering ? Color.blue : Color.clear)
            .onHover { hover in
                self.hovering = hover
            }
    }
}
