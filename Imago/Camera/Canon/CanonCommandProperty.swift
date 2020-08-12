//
//  CanonCommandProperty.swift
//  Imago
//
//  Created by Nolan Brown on 7/8/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

import Foundation

// The majority of these aren't used but are available here in case they're set as part of the EDSDK Property Change Handler
struct CanonProperty : Hashable, Identifiable, CustomDebugStringConvertible {
    var id: EdsPropertyID
    var name: String
    var stringValue: String?
    var dataValue: Data?
    var dataType: EdsDataType?
    var intValue: UInt32?
    
    init(_ name: String, _ edsPropertyID: EdsPropertyID) {
        self.name = name
        self.id = edsPropertyID
    }
    
    init(id:EdsPropertyID, name: String, stringValue: String?, dataValue: Data?, dataType: EdsDataType?, intValue: UInt32?) {
        self.id = id
        self.name = name
        self.stringValue = stringValue
        self.dataValue = dataValue
        self.dataType = dataType
        self.intValue = intValue

    }
    
    static func forID(_ propertyID: EdsPropertyID) -> CanonProperty {
        return GetProperyForEdsPropertyID(propertyID)
    }
    
    func withValue(_ data: Data, _ type: EdsDataType) -> CanonProperty {
        return CanonProperty(id: self.id, name: self.name, stringValue: nil, dataValue: data, dataType: type, intValue: nil)
    }
    func withValue(_ str: String) -> CanonProperty {
        return CanonProperty(id: self.id, name: self.name, stringValue: str, dataValue: nil, dataType: nil, intValue: nil)
    }
    func withValue(_ i: UInt32) -> CanonProperty {
        return CanonProperty(id: self.id, name: self.name, stringValue: nil, dataValue: nil, dataType: nil, intValue: i)
    }
    
    static func == (lhs: CanonProperty, rhs: CanonProperty) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(stringValue)
        hasher.combine(dataValue)
        hasher.combine(intValue)
    }
    var debugDescription: String {
        if self.stringValue != nil {
            return "CanonProperty(id: \(id) name: \(name) value: \(self.stringValue!))"
        }
        else if self.dataValue != nil {
            return "CanonProperty(id: \(id) name: \(name) value: \(self.dataValue!))"
        }
        else if self.intValue != nil {
            return "CanonProperty(id: \(id) name: \(name) value: \(self.intValue!))"
        }
        return "CanonProperty(id: \(id) name: \(name) value: nil)"
    }
}

func GetProperyForEdsPropertyID(_ propertyID: EdsPropertyID) -> CanonProperty {
    switch propertyID {
        case EdsPropertyID(kEdsPropID_Unknown): return CanonProperty("Unknown", EdsPropertyID(kEdsPropID_Unknown))
        case EdsPropertyID(kEdsPropID_ProductName): return CanonProperty("ProductName", EdsPropertyID(kEdsPropID_ProductName))
        case EdsPropertyID(kEdsPropID_OwnerName): return CanonProperty("OwnerName", EdsPropertyID(kEdsPropID_OwnerName))
        case EdsPropertyID(kEdsPropID_MakerName): return CanonProperty("MakerName", EdsPropertyID(kEdsPropID_MakerName))
        case EdsPropertyID(kEdsPropID_DateTime): return CanonProperty("DateTime", EdsPropertyID(kEdsPropID_DateTime))
        case EdsPropertyID(kEdsPropID_FirmwareVersion): return CanonProperty("FirmwareVersion", EdsPropertyID(kEdsPropID_FirmwareVersion))
        case EdsPropertyID(kEdsPropID_BatteryLevel): return CanonProperty("BatteryLevel", EdsPropertyID(kEdsPropID_BatteryLevel))
        case EdsPropertyID(kEdsPropID_CFn): return CanonProperty("CFn", EdsPropertyID(kEdsPropID_CFn))
        case EdsPropertyID(kEdsPropID_SaveTo): return CanonProperty("SaveTo", EdsPropertyID(kEdsPropID_SaveTo))
        case EdsPropertyID(kEdsPropID_CurrentStorage): return CanonProperty("CurrentStorage", EdsPropertyID(kEdsPropID_CurrentStorage))
        case EdsPropertyID(kEdsPropID_CurrentFolder): return CanonProperty("CurrentFolder", EdsPropertyID(kEdsPropID_CurrentFolder))
        case EdsPropertyID(kEdsPropID_BatteryQuality): return CanonProperty("BatteryQuality", EdsPropertyID(kEdsPropID_BatteryQuality))
        case EdsPropertyID(kEdsPropID_BodyIDEx): return CanonProperty("BodyIDEx", EdsPropertyID(kEdsPropID_BodyIDEx))
        case EdsPropertyID(kEdsPropID_HDDirectoryStructure): return CanonProperty("HDDirectoryStructure", EdsPropertyID(kEdsPropID_HDDirectoryStructure))
        case EdsPropertyID(kEdsPropID_ImageQuality): return CanonProperty("ImageQuality", EdsPropertyID(kEdsPropID_ImageQuality))
        case EdsPropertyID(kEdsPropID_Orientation): return CanonProperty("Orientation", EdsPropertyID(kEdsPropID_Orientation))
        case EdsPropertyID(kEdsPropID_ICCProfile): return CanonProperty("ICCProfile", EdsPropertyID(kEdsPropID_ICCProfile))
        case EdsPropertyID(kEdsPropID_FocusInfo): return CanonProperty("FocusInfo", EdsPropertyID(kEdsPropID_FocusInfo))
        case EdsPropertyID(kEdsPropID_WhiteBalance): return CanonProperty("WhiteBalance", EdsPropertyID(kEdsPropID_WhiteBalance))
        case EdsPropertyID(kEdsPropID_ColorTemperature): return CanonProperty("ColorTemperature", EdsPropertyID(kEdsPropID_ColorTemperature))
        case EdsPropertyID(kEdsPropID_WhiteBalanceShift): return CanonProperty("WhiteBalanceShift", EdsPropertyID(kEdsPropID_WhiteBalanceShift))
        case EdsPropertyID(kEdsPropID_ColorSpace): return CanonProperty("ColorSpace", EdsPropertyID(kEdsPropID_ColorSpace))
        case EdsPropertyID(kEdsPropID_PictureStyle): return CanonProperty("PictureStyle", EdsPropertyID(kEdsPropID_PictureStyle))
        case EdsPropertyID(kEdsPropID_PictureStyleDesc): return CanonProperty("PictureStyleDesc", EdsPropertyID(kEdsPropID_PictureStyleDesc))
        case EdsPropertyID(kEdsPropID_PictureStyleCaption): return CanonProperty("PictureStyleCaption", EdsPropertyID(kEdsPropID_PictureStyleCaption))
        case EdsPropertyID(kEdsPropID_GPSVersionID): return CanonProperty("GPSVersionID", EdsPropertyID(kEdsPropID_GPSVersionID))
        case EdsPropertyID(kEdsPropID_GPSLatitudeRef): return CanonProperty("GPSLatitudeRef", EdsPropertyID(kEdsPropID_GPSLatitudeRef))
        case EdsPropertyID(kEdsPropID_GPSLatitude): return CanonProperty("GPSLatitude", EdsPropertyID(kEdsPropID_GPSLatitude))
        case EdsPropertyID(kEdsPropID_GPSLongitudeRef): return CanonProperty("GPSLongitudeRef", EdsPropertyID(kEdsPropID_GPSLongitudeRef))
        case EdsPropertyID(kEdsPropID_GPSLongitude): return CanonProperty("GPSLongitude", EdsPropertyID(kEdsPropID_GPSLongitude))
        case EdsPropertyID(kEdsPropID_GPSAltitudeRef): return CanonProperty("GPSAltitudeRef", EdsPropertyID(kEdsPropID_GPSAltitudeRef))
        case EdsPropertyID(kEdsPropID_GPSAltitude): return CanonProperty("GPSAltitude", EdsPropertyID(kEdsPropID_GPSAltitude))
        case EdsPropertyID(kEdsPropID_GPSTimeStamp): return CanonProperty("GPSTimeStamp", EdsPropertyID(kEdsPropID_GPSTimeStamp))
        case EdsPropertyID(kEdsPropID_GPSSatellites): return CanonProperty("GPSSatellites", EdsPropertyID(kEdsPropID_GPSSatellites))
        case EdsPropertyID(kEdsPropID_GPSStatus): return CanonProperty("GPSStatus", EdsPropertyID(kEdsPropID_GPSStatus))
        case EdsPropertyID(kEdsPropID_GPSMapDatum): return CanonProperty("GPSMapDatum", EdsPropertyID(kEdsPropID_GPSMapDatum))
        case EdsPropertyID(kEdsPropID_GPSDateStamp): return CanonProperty("GPSDateStamp", EdsPropertyID(kEdsPropID_GPSDateStamp))
        case EdsPropertyID(kEdsPropID_AEMode): return CanonProperty("AEMode", EdsPropertyID(kEdsPropID_AEMode))
        case EdsPropertyID(kEdsPropID_DriveMode): return CanonProperty("DriveMode", EdsPropertyID(kEdsPropID_DriveMode))
        case EdsPropertyID(kEdsPropID_ISOSpeed): return CanonProperty("ISOSpeed", EdsPropertyID(kEdsPropID_ISOSpeed))
        case EdsPropertyID(kEdsPropID_MeteringMode): return CanonProperty("MeteringMode", EdsPropertyID(kEdsPropID_MeteringMode))
        case EdsPropertyID(kEdsPropID_AFMode): return CanonProperty("AFMode", EdsPropertyID(kEdsPropID_AFMode))
        case EdsPropertyID(kEdsPropID_Av): return CanonProperty("Av", EdsPropertyID(kEdsPropID_Av))
        case EdsPropertyID(kEdsPropID_Tv): return CanonProperty("Tv", EdsPropertyID(kEdsPropID_Tv))
        case EdsPropertyID(kEdsPropID_ExposureCompensation): return CanonProperty("ExposureCompensation", EdsPropertyID(kEdsPropID_ExposureCompensation))
        case EdsPropertyID(kEdsPropID_FocalLength): return CanonProperty("FocalLength", EdsPropertyID(kEdsPropID_FocalLength))
        case EdsPropertyID(kEdsPropID_AvailableShots): return CanonProperty("AvailableShots", EdsPropertyID(kEdsPropID_AvailableShots))
        case EdsPropertyID(kEdsPropID_Bracket): return CanonProperty("Bracket", EdsPropertyID(kEdsPropID_Bracket))
        case EdsPropertyID(kEdsPropID_WhiteBalanceBracket): return CanonProperty("WhiteBalanceBracket", EdsPropertyID(kEdsPropID_WhiteBalanceBracket))
        case EdsPropertyID(kEdsPropID_LensName): return CanonProperty("LensName", EdsPropertyID(kEdsPropID_LensName))
        case EdsPropertyID(kEdsPropID_AEBracket): return CanonProperty("AEBracket", EdsPropertyID(kEdsPropID_AEBracket))
        case EdsPropertyID(kEdsPropID_FEBracket): return CanonProperty("FEBracket", EdsPropertyID(kEdsPropID_FEBracket))
        case EdsPropertyID(kEdsPropID_ISOBracket): return CanonProperty("ISOBracket", EdsPropertyID(kEdsPropID_ISOBracket))
        case EdsPropertyID(kEdsPropID_NoiseReduction): return CanonProperty("NoiseReduction", EdsPropertyID(kEdsPropID_NoiseReduction))
        case EdsPropertyID(kEdsPropID_FlashOn): return CanonProperty("FlashOn", EdsPropertyID(kEdsPropID_FlashOn))
        case EdsPropertyID(kEdsPropID_RedEye): return CanonProperty("RedEye", EdsPropertyID(kEdsPropID_RedEye))
        case EdsPropertyID(kEdsPropID_FlashMode): return CanonProperty("FlashMode", EdsPropertyID(kEdsPropID_FlashMode))
        case EdsPropertyID(kEdsPropID_LensStatus): return CanonProperty("LensStatus", EdsPropertyID(kEdsPropID_LensStatus))
        case EdsPropertyID(kEdsPropID_Artist): return CanonProperty("Artist", EdsPropertyID(kEdsPropID_Artist))
        case EdsPropertyID(kEdsPropID_Copyright): return CanonProperty("Copyright", EdsPropertyID(kEdsPropID_Copyright))
        case EdsPropertyID(kEdsPropID_AEModeSelect): return CanonProperty("AEModeSelect", EdsPropertyID(kEdsPropID_AEModeSelect))
        case EdsPropertyID(kEdsPropID_PowerZoom_Speed): return CanonProperty("PowerZoom_Speed", EdsPropertyID(kEdsPropID_PowerZoom_Speed))
        case EdsPropertyID(kEdsPropID_Evf_OutputDevice): return CanonProperty("Evf_OutputDevice", EdsPropertyID(kEdsPropID_Evf_OutputDevice))
        case EdsPropertyID(kEdsPropID_Evf_Mode): return CanonProperty("Evf_Mode", EdsPropertyID(kEdsPropID_Evf_Mode))
        case EdsPropertyID(kEdsPropID_Evf_WhiteBalance): return CanonProperty("Evf_WhiteBalance", EdsPropertyID(kEdsPropID_Evf_WhiteBalance))
        case EdsPropertyID(kEdsPropID_Evf_ColorTemperature): return CanonProperty("Evf_ColorTemperature", EdsPropertyID(kEdsPropID_Evf_ColorTemperature))
        case EdsPropertyID(kEdsPropID_Evf_DepthOfFieldPreview): return CanonProperty("Evf_DepthOfFieldPreview", EdsPropertyID(kEdsPropID_Evf_DepthOfFieldPreview))
        case EdsPropertyID(kEdsPropID_Evf_Zoom): return CanonProperty("Evf_Zoom", EdsPropertyID(kEdsPropID_Evf_Zoom))
        case EdsPropertyID(kEdsPropID_Evf_ZoomPosition): return CanonProperty("Evf_ZoomPosition", EdsPropertyID(kEdsPropID_Evf_ZoomPosition))
        case EdsPropertyID(kEdsPropID_Evf_Histogram): return CanonProperty("Evf_Histogram", EdsPropertyID(kEdsPropID_Evf_Histogram))
        case EdsPropertyID(kEdsPropID_Evf_ImagePosition): return CanonProperty("Evf_ImagePosition", EdsPropertyID(kEdsPropID_Evf_ImagePosition))
        case EdsPropertyID(kEdsPropID_Evf_HistogramStatus): return CanonProperty("Evf_HistogramStatus", EdsPropertyID(kEdsPropID_Evf_HistogramStatus))
        case EdsPropertyID(kEdsPropID_Evf_AFMode): return CanonProperty("Evf_AFMode", EdsPropertyID(kEdsPropID_Evf_AFMode))
        case EdsPropertyID(kEdsPropID_Record): return CanonProperty("Record", EdsPropertyID(kEdsPropID_Record))
        case EdsPropertyID(kEdsPropID_Evf_HistogramY): return CanonProperty("Evf_HistogramY", EdsPropertyID(kEdsPropID_Evf_HistogramY))
        case EdsPropertyID(kEdsPropID_Evf_HistogramR): return CanonProperty("Evf_HistogramR", EdsPropertyID(kEdsPropID_Evf_HistogramR))
        case EdsPropertyID(kEdsPropID_Evf_HistogramG): return CanonProperty("Evf_HistogramG", EdsPropertyID(kEdsPropID_Evf_HistogramG))
        case EdsPropertyID(kEdsPropID_Evf_HistogramB): return CanonProperty("Evf_HistogramB", EdsPropertyID(kEdsPropID_Evf_HistogramB))
        case EdsPropertyID(kEdsPropID_Evf_CoordinateSystem): return CanonProperty("Evf_CoordinateSystem", EdsPropertyID(kEdsPropID_Evf_CoordinateSystem))
        case EdsPropertyID(kEdsPropID_Evf_ZoomRect): return CanonProperty("Evf_ZoomRect", EdsPropertyID(kEdsPropID_Evf_ZoomRect))
        case EdsPropertyID(kEdsPropID_Evf_ImageClipRect): return CanonProperty("Evf_ImageClipRect", EdsPropertyID(kEdsPropID_Evf_ImageClipRect))
        case EdsPropertyID(kEdsPropID_Evf_PowerZoom_CurPosition): return CanonProperty("Evf_PowerZoom_CurPosition", EdsPropertyID(kEdsPropID_Evf_PowerZoom_CurPosition))
        case EdsPropertyID(kEdsPropID_Evf_PowerZoom_MaxPosition): return CanonProperty("Evf_PowerZoom_MaxPosition", EdsPropertyID(kEdsPropID_Evf_PowerZoom_MaxPosition))
        case EdsPropertyID(kEdsPropID_Evf_PowerZoom_MinPosition): return CanonProperty("Evf_PowerZoom_MinPosition", EdsPropertyID(kEdsPropID_Evf_PowerZoom_MinPosition))
        case EdsPropertyID(kEdsPropID_TempStatus): return CanonProperty("TempStatus", EdsPropertyID(kEdsPropID_TempStatus))
        case EdsPropertyID(kEdsPropID_EVF_RollingPitching): return CanonProperty("EVF_RollingPitching", EdsPropertyID(kEdsPropID_EVF_RollingPitching))
        case EdsPropertyID(kEdsPropID_FixedMovie): return CanonProperty("FixedMovie", EdsPropertyID(kEdsPropID_FixedMovie))
        case EdsPropertyID(kEdsPropID_MovieParam): return CanonProperty("MovieParam", EdsPropertyID(kEdsPropID_MovieParam))
        case EdsPropertyID(kEdsPropID_Evf_ClickWBCoeffs): return CanonProperty("Evf_ClickWBCoeffs", EdsPropertyID(kEdsPropID_Evf_ClickWBCoeffs))
        case EdsPropertyID(kEdsPropID_ManualWhiteBalanceData): return CanonProperty("ManualWhiteBalanceData", EdsPropertyID(kEdsPropID_ManualWhiteBalanceData))
        case EdsPropertyID(kEdsPropID_MirrorUpSetting): return CanonProperty("MirrorUpSetting", EdsPropertyID(kEdsPropID_MirrorUpSetting))
        case EdsPropertyID(kEdsPropID_MirrorLockUpState): return CanonProperty("MirrorLockUpState", EdsPropertyID(kEdsPropID_MirrorLockUpState))
        case EdsPropertyID(kEdsPropID_UTCTime): return CanonProperty("UTCTime", EdsPropertyID(kEdsPropID_UTCTime))
        case EdsPropertyID(kEdsPropID_TimeZone): return CanonProperty("TimeZone", EdsPropertyID(kEdsPropID_TimeZone))
        case EdsPropertyID(kEdsPropID_SummerTimeSetting): return CanonProperty("SummerTimeSetting", EdsPropertyID(kEdsPropID_SummerTimeSetting))
        case EdsPropertyID(kEdsPropID_DC_Zoom): return CanonProperty("DC_Zoom", EdsPropertyID(kEdsPropID_DC_Zoom))
        case EdsPropertyID(kEdsPropID_DC_Strobe): return CanonProperty("DC_Strobe", EdsPropertyID(kEdsPropID_DC_Strobe))
        case EdsPropertyID(kEdsPropID_LensBarrelStatus): return CanonProperty("LensBarrelStatus", EdsPropertyID(kEdsPropID_LensBarrelStatus))
        default:
            return CanonProperty("Unknown", EdsPropertyID(kEdsPropID_Unknown))
    }
}
