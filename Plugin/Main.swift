//
//  Main.swift
//  Imago
//
//  Created by Nolan Brown on 7/3/20.
//

import Foundation
import CoreMediaIO

@_cdecl("ImagoPluginMain")
public func ImagoPluginMain(allocator: CFAllocator, requestedTypeUUID: CFUUID) -> CMIOHardwarePlugInRef {
    return pluginRef
}
