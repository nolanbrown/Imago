# Imago 

## Introduction

This project is named after the [Imago Camera](https://en.wikipedia.org/wiki/Imago_camera) created by Werner Kraus, which was created to capture images at the life size of a subject. 

I created Imago to replace multiple apps that allowed me to use my [Canon M50](https://www.amazon.com/Canon-Mirrorless-Camera-EF-M15-45mm-Video/dp/B079Y45KTJ/) as a Virtual Camera for apps like Zoom. I was using the wonderful [Camera Live](https://github.com/v002/v002-Camera-Live) by [Tom Butterworth (@bangnoise)](https://github.com/bangnoise) and [CamTwist](http://camtwiststudio.com/), both of which have worked extraordinarily well. I encourage you to take a look at both to decide which is a better solution for you.

The DAL plugin is based off of [SimpleDALPlugin](https://github.com/seanchas116/SimpleDALPlugin) by [Ryohei Ikegami (@seanchas116)](https://github.com/seanchas116), who migrated [CoreMediaIO Device Abstraction Layer Minimal Example](https://github.com/johnboiles/coremediaio-dal-minimal-example) by [John Boiles  (@johnboiles)](https://github.com/johnboiles) into Swift.

The UI is written in SwiftUI for macOS 10.15, so it is missing some of the nicities that were added for macOS 11. 

## System Requirements

- macOS 10.15
- Compatible Canon Camera

## Architecture

**Caveat:** _This is my first Swift app, so if there are better ways to do something please let me know._

The project is split into two Targets, _Imago_ is the macOS app and _ImagoPlugin_ is the Virtual Camera plugin (aka Device Abstraction Layer). 

Beyond the base implementation of the CMIO Plugin, _ImagoPlugin_ is only responsible for communicating with _Imago_ and reconstituing the raw data back into a `CVPixelBuffer`. This is accomplished by setting up dedicated inter-process communications using [CFMessagePort](https://developer.apple.com/documentation/corefoundation/cfmessageport-rs2).

The _Imago_ app is responsible for all communications and data management between the Camera (via the EDSDK.framework), image decompression, and coordinates all the inter-process communications to active instances of _ImagoPlugin_.

### Camera Communications
Communications between _Imago_ and the EDSDK can be summarized as:
1. Initialize EDSDK
2. Get the available list of Cameras
3. Connect to a selected Camera
4. Get required properties about the Camera
5. Set the Camera Output mode
5. Get Image Data

All EDSDK calls are in the `CanonCamera` subclass of `Camera` where they're coordinated using a dedicated DispatchQueue.

### Imago <=> Imago Plugin Communcations

For a primer on inter-process communications, check out this [NSHipster post](https://nshipster.com/inter-process-communication/) by [@Mattt](https://nshipster.com/authors/mattt/).

_Imago_ uses CFMessagePort, which in turn uses Mach Ports under the hood. These provide fast, dedicated communication channels between processes that allow _Imago_ to push image data directly into _ImagoPlugin_. The main limitation of them is they only provide only 1:1 communications. Given that there can be multiple instances of an _ImagoPlugin_ running if a user has multiple client programs running (for example Zoom and Google Meet in Chrome), _Imago_ implements a Publisher/Subscriber architecture to allow for dedicated 1:1 communication between multiple processes. There are other ways of acheving the same result, either by using lower level Mach Ports or higher level XPC, and passing an IOSurface object between processess; however both those ways are more complicated then using CFMessagePort.


1. Start Publisher at known port address (ie. `com.nolanbrown.Imago.conductor.publisher`)
    - If a Publisher isn't available, the Subscriber will periodically attempt to connect until it's able to establish a connection
2. When a Subscriber is ready to connect to the Publisher, it will create a UUID and open a local port address using that ID (ie  `com.nolanbrown.Imago.conductor.e02d59bd-16fa-41a0-bf70-70adfc02e877`)
3. When Publisher receives a `Register` message from a subscriber process , it will open a remote port the Subcriber at that ID
4. Publisher sends data to all confirmed Subscribers
5. A Subscriber will periodically `Register` with the Publisher to confirm that both connections 



## Building


To get started building _Imago_, first the required libraries must be downloaded. To simplify this process, you only need to run `setup.sh` that's in the root directory of this project. The script will install and setup `libturbo-jpeg` and the `Canon EOS SDK`, once that's completed you can build the project. 

_ImagoPlugin_ is set as a dependecy for _Imago_, so the plugin will be automatically built every time _Imago_ is.

### Imago Plugin Installation
To use the _ImagoPlugin_, it needs to be installed in `/Library/CoreMediaIO/Plug-Ins/DAL/`. It can be tedious to manually copy the plugin so there is a Run Script build phase that will automatically move the newly built `ImagoPlugin.plugin` to that directory.

The Run Script requires a sudoer password to be provided which is done via a query to the Keychain. To set this up for yourself, create a new entry in Keychain Access with both Item Name and Account Name set as `ImagoBuild` and enter a password for a Sudo user, or create a new Keychain Item from the command line with the command  `security add-generic-password -a ImagoBuild -s ImagoBuild -w` and enter a password for Sudo user.

Below is the executed Run Script to automatically install the built plugin.
```
if [ $CONFIGURATION == "Debug" ];then
    echo $(security find-generic-password -ga "ImagoBuild" -w) | sudo -S rm -R /Library/CoreMediaIO/Plug-Ins/DAL/$PRODUCT_NAME.plugin; 
    sudo cp -R $SYMROOT/$CONFIGURATION/$PRODUCT_NAME.plugin /Library/CoreMediaIO/Plug-Ins/DAL/$PRODUCT_NAME.plugin
fi
```

### Required Libaries

#### EDSDK (Canon EOS SDK)
To download the EDSDK.framework, register for a developer account with Canon. For US developers, you can do that [here](https://developercommunity.usa.canon.com/canon) and then [download the SDK](https://developercommunity.usa.canon.com/canon?id=sdk_download).

Once downloaded, unzip the file and open `Macintosh.dmg`. From the mounted disk image  `Macintosh` copy  `EDSDK/Framework/EDSDK.framework` to `<PROJECT_ROOT>/Frameworks/EDSDK/EDSDK.framework` and the  `Header` directory to `<PROJECT_ROOT>/Frameworks/EDSDK/Header/`



#### libjpeg-turbo

You can download the latest version of the libjpeg-turbo binary [here](https://sourceforge.net/projects/libjpeg-turbo/files/) or visit their [website](https://libjpeg-turbo.org/Documentation/OfficialBinaries).



## Debugging

Use [Cameo](https://github.com/lvsti/Cameo) to load and test the _ImagoPlugin_ or use any application that allow for Virtual Cameras.


### Notes
The error `"The file “ic_hevcdec.framework” couldn’t be opened because there is no such file."` is part of EDSDK and can be ignored.


## Troubleshooting
- Connect your camera via USB directly to your computer, not through a USB hub or Dock
- Try a different USB cable
- Turn off any other apps that are communicating with the Camera (EOS Utility, Camera Live, etc)
- Turn off your camera and turn it back on again


## Credits

### [Icon By KDesign](https://dribbble.com/shots/7485922-Abstract-icons)

## TODO

- [ ] Improve Plugin re-connection
- [ ] Test with more Canon Cameras
- [ ] Implement an iOS App to act as remote camera
- [ ] Add more filter options and ability to configure
- [ ] Add a Live Preview mode
- [ ] Add preferences pane
- [ ] Add support for other DSLR manufacturers
- [ ] Calculate and Display frame rate 
- [ ] Fix UI bugs on macOS 11
