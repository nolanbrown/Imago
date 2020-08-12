#!/bin/bash

PROJECTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TURBOJPEG_LIB_NAME=libturbojpeg.0.dylib
TURBOJPEG_LIB_PATH=/opt/libjpeg-turbo/lib/$TURBOJPEG_LIB_NAME

TURBOJPEG_RELEASE_URL=https://sourceforge.net/projects/libjpeg-turbo/files/

FRAMEWORKS_DIR=Frameworks


EDSDK_ZIP_URL=https://downloads.canon.com/sdk/EDSDK_v131231_Macintosh.zip

if [ ! -d "Imago.xcodeproj" ]; then
    echo "This script must be executed in the base directory of the Imago project"
    exit 1
fi

installTurboJpeg() {
    if [ -f "$TURBOJPEG_LIB_PATH" ]; then
        return 0
    else
        if isBrewInstalled; then
            while true; do
                read -p "Do you wish to install TurboJPEG?" yn
                case $yn in
                    [Yy]* ) brew install jpeg-turbo; return installTurboJpeg;;
                    [Nn]* ) askUserToInstallTurboJpeg ;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            askUserToInstallTurboJpeg
        fi
    fi
}

askUserToInstallTurboJpeg() {
    echo "TurboJPEG not found. Please install and re-run this script"
    open $TURBOJPEG_RELEASE_URL
    exit
}

isBrewInstalled() {
    which -s brew
    if [[ $? != 0 ]] ; then
        return 0
    else
        return 1
    fi
}

isTurboJpegSetup() {
    if [ -f "$FRAMEWORKS_DIR/$TURBOJPEG_LIB_NAME" ]; then
        return 0
    else
        return 1
    fi
}

setupTurboJpegAsFramework() {
    if installTurboJpeg; then
        local newLibPath=$FRAMEWORKS_DIR/$TURBOJPEG_LIB_NAME

        if [ -f "$TURBOJPEG_LIB_PATH" ]; then
            echo "Copying $TURBOJPEG_LIB_NAME to $newLibPath"
            cp $TURBOJPEG_LIB_PATH $newLibPath

            echo "Updating $TURBOJPEG_LIB_NAME location to look in app bundle"
            install_name_tool -id @executable_path/../Frameworks/$TURBOJPEG_LIB_NAME $newLibPath

            echo "Updating $TURBOJPEG_LIB_NAME use system libgcc"
            install_name_tool -change /opt/local/lib/libgcc/libgcc_s.1.dylib /usr/lib/libgcc_s.1.dylib $newLibPath

            echo "Removing uncessary architectures from $TURBOJPEG_LIB_NAME"
            lipo -thin x86_64 $newLibPath -o $newLibPath
        fi
    else
        echo "TurboJPEG could not be installed."
    fi

}

isEDSDKSetup() {
    if [ -d "$PROJECTDIR/$FRAMEWORKS_DIR/EDSDK/EDSDK.framework" ]; then
        return 0
    else
        return 1
    fi
}

setupEDSDKAsFramework() {
    local tmpDir=`mktemp -d`
    local zipName=$(basename $EDSDK_ZIP_URL)

    local diskImageName=Macintosh.dmg
    local mountedImagePath=/Volumes/Macintosh
    local edsdkDirectory="$mountedImagePath/EDSDK"

    local frameworkDirectory="$PROJECTDIR/$FRAMEWORKS_DIR/EDSDK"

    local frameworkName=EDSDK.framework


    if [ ! -d "$frameworkDirectory/$frameworkName" ]; then

        cd $tmpDir

        echo "Downloading EDSDK.framework..."
        curl -O $EDSDK_ZIP_URL &> /dev/null

        if [ ! -f $zipName ]; then
            echo "Download of $EDSDK_ZIP_URL failed"
            cd $PROJECTDIR
            return 1
        fi

        echo "Unziping EDSDK"
        unzip -a $zipName &> /dev/null
        unzip -a "$diskImageName.zip" &> /dev/null

        if [ ! -f $diskImageName ]; then
            echo "EDSDK disk image not found. Can not complete setup"
            cd $PROJECTDIR
            return 1
        fi

        echo "Attaching EDSDK disk image"
        hdiutil attach $diskImageName &> /dev/null

        echo "Creating required directory structure"
        mkdir -p $frameworkDirectory/Header

        echo "Copying $frameworkName and Headers"
        cp -R $edsdkDirectory/Framework/$frameworkName $frameworkDirectory/$frameworkName
        cp -R $edsdkDirectory/Header/* $frameworkDirectory/Header/

        echo "Cleaning up..."
        hdiutil detach $mountedImagePath &> /dev/null

        cd $PROJECTDIR

        echo "Done"
    fi
}


if isTurboJpegSetup; then
    echo "TurboJPEG is setup for Imago"
else
    setupTurboJpegAsFramework
fi


if isEDSDKSetup; then
    echo "EDSDK is setup for Imago"
else
    setupEDSDKAsFramework
fi





