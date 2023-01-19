//
//  CommonTools.swift
//  CommonTools
//
//  Created by WeiJun on 2021/5/3.
//

import Foundation
import UIKit
import Network
import SystemConfiguration.CaptiveNetwork
import WebKit
import GLKit
import NetworkExtension

public enum WEPInvalidType {
    case ValidWEPType
    case InvalidWEPASCIIType
    case InvalidWEPHEXType
    case InvalidWEPLengthType
}

public enum WPAInvalidType {
    case ValidWPAType,
         InvalidWPAASCIIType,
         InvalidWPAHEXType,
         InvalidWPALengthType
}

public enum StaticIPInfoType {
    case StaticIPInfoIPType,
         StaticIPInfoGatewayType
}

public class WifiInfoClass {
    public var bssid: String?
    public var ssid: String?
}

public class LocalIPInfoClass {
    public var currentInterfaceIP: String?
    public var wifiIP: String?
    public var cellularIP: String?
    public var currentInterfaceMask: String?
    public var wifiMask: String?
    public var cellularMask: String?
}

let GOOD_IRI_CHAR: String = "a-zA-Z0-9\\u00A0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF"
let TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL: String = "(?:(?:aero|arpa|asia|a[cdefgilmnoqrstuwxz])|(?:biz|b[abdefghijmnorstvwyz])|(?:cat|com|coop|c[acdfghiklmnoruvxyz])|d[ejkmoz]|(?:edu|e[cegrstu])|f[ijkmor]|(?:gov|g[abdefghilmnpqrstuwy])|h[kmnrtu]|(?:info|int|i[delmnoqrst])|(?:jobs|j[emop])|k[eghimnprwyz]|l[abcikrstuvy]|(?:mil|mobi|museum|m[acdeghklmnopqrstuvwxyz])|(?:name|net|n[acefgilopruz])|(?:org|om)|(?:pro|p[aefghklmnrstwy])|qa|r[eosuw]|s[abcdeghijklmnortuvyz]|(?:tel|travel|t[cdfghjklmnoprtvwz])|u[agksyz]|v[aceginu]|w[fs]|(?:xn\\-\\-0zwm56d|xn\\-\\-11b5bs3a9aj6g|xn\\-\\-80akhbyknj4f|xn\\-\\-9t4b11yi5a|xn\\-\\-deba0ad|xn\\-\\-g6w251d|xn\\-\\-hgbk6aj7f53bba|xn\\-\\-hlcj6aya9esc7a|xn\\-\\-jxalpdlp|xn\\-\\-kgbechtv|xn\\-\\-zckzah)|y[etu]|z[amw]))"

public class CommonTools {
    //MARK: - Library Info
    //Get libary version
    public class func getLibraryVersion() -> String {
        return "1.0.2111040"
    }
    
    //MARK: - About System
    //Get iOS version with int number
    public class func getIosVersionNumber() -> Int {
        let vComp: Array = UIDevice.current.systemVersion.components(separatedBy: ".")
        return Int(vComp[0])!
    }
    //Get iOS version with string
    public class func getIosVersionString() -> String {
        return UIDevice.current.systemVersion
    }
    //Get APP version with string
    public class func getAppVersionName() -> String {
        let plistData: Dictionary = Bundle.main.infoDictionary!
        let version: String = plistData["CFBundleVersion"] as! String
        return version
    }
    //Get device screen size
    public class func getScreenSize() -> CGSize {
        var rtnSize: CGSize
        
        let screenRect: CGRect = UIScreen.main.bounds
        let screenHeight: CGFloat = screenRect.size.height
        let screenWidth: CGFloat = screenRect.size.width
        var setHeight: CGFloat = screenHeight
        var setWidth: CGFloat = screenWidth
        if UIApplication.shared.statusBarOrientation.isLandscape {
            //if landscape mode , switch width and height
            setHeight = screenWidth
            setWidth = screenHeight
        }
        rtnSize = CGSize(width: setWidth, height: setHeight)
        return rtnSize
    }
    
    //MARK: - About Network
    public class func startReachability() -> Reachability {
        let reachability: Reachability = Reachability.forInternetConnection()
        return reachability
    }
    //Get current network interface
    public class func detectNetworkInterface() -> NetworkStatus {
        let reachability: Reachability = Reachability.forInternetConnection()
        reachability.startNotifier()
        return reachability.currentReachabilityStatus()
    }
    
    //Get current wifi info
    public class func fetchWifiInfo(completionHandler: @escaping (WifiInfoClass?) -> Void) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { currentNetwork in
                if let currentNetwork = currentNetwork {
                    let wifiInfo: WifiInfoClass = WifiInfoClass()
                    wifiInfo.ssid = currentNetwork.ssid
                    wifiInfo.bssid = currentNetwork.bssid
                    completionHandler(wifiInfo)
                    return
                }
                completionHandler(nil)
            }
            return
        }
        
        if let interfaces: NSArray = CNCopySupportedInterfaces() {
            for interface in interfaces {
                let interfaceName = interface as! String
                let wifiInfo: WifiInfoClass = WifiInfoClass()
                
                if let dict = CNCopyCurrentNetworkInfo(interfaceName as CFString) as NSDictionary? {
                    wifiInfo.ssid = dict[kCNNetworkInfoKeySSID as String] as? String
                    wifiInfo.bssid = dict[kCNNetworkInfoKeyBSSID as String] as? String
                    completionHandler(wifiInfo)
                    return
                }
            }
        }
        
        completionHandler(nil)
        
    }
    
    class func standardFormateMAC(MAC: String) -> String{
        let subStr: Array = MAC.components(separatedBy: ":")
        var subStr_M: Array = [String]()
        for str in subStr {
            if str.count == 1 {
                let tmpStr: String = "0\(str)"
                subStr_M.append(tmpStr)
            }else {
                subStr_M.append(str)
            }
        }
        let formateMAC: String = subStr_M.joined(separator: ":")
        return formateMAC.uppercased()
    }
    //Get current local ip info
    public class func getLocalIPInfo() -> LocalIPInfoClass {
        var wifiAddress: String? = nil
        var wifiNetMask: String? = nil
        var cellAddress: String? = nil
        var cellNetMask: String? = nil
        var interfaces : UnsafeMutablePointer<ifaddrs>? = nil
        var temp_addr : UnsafeMutablePointer<ifaddrs>? = nil
        let success = getifaddrs(&interfaces)
        // retrieve the current interfaces - returns 0 on success
        if success == 0 {
            // Loop through linked list of interfaces
            temp_addr = interfaces
            while temp_addr != nil {
                if temp_addr!.pointee.ifa_addr.pointee.sa_family == AF_INET {
                    // Check if interface is en0 which is the wifi connection on the iPhone
                    if String(cString: temp_addr!.pointee.ifa_name) == "en0" {
                        var address = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(temp_addr!.pointee.ifa_addr, socklen_t(temp_addr!.pointee.ifa_addr.pointee.sa_len),
                                    &address, socklen_t(address.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        wifiAddress = String(cString: address)
                        var mask = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(temp_addr!.pointee.ifa_netmask, socklen_t(temp_addr!.pointee.ifa_netmask.pointee.sa_len),
                                    &mask, socklen_t(mask.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        wifiNetMask = String(cString: mask)
                    }
                    
                    if String(cString: temp_addr!.pointee.ifa_name) == "pdp_ip0" {
                        var address = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(temp_addr!.pointee.ifa_addr, socklen_t(temp_addr!.pointee.ifa_addr.pointee.sa_len),
                                    &address, socklen_t(address.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        cellAddress = String(cString: address)
                        var mask = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(temp_addr!.pointee.ifa_netmask, socklen_t(temp_addr!.pointee.ifa_netmask.pointee.sa_len),
                                    &mask, socklen_t(mask.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        cellNetMask = String(cString: mask)
                    }
                }
                
                temp_addr = temp_addr!.pointee.ifa_next
            }
        }
        // Free memory
        freeifaddrs(interfaces)
        
        let localIPInfo: LocalIPInfoClass = LocalIPInfoClass()
        localIPInfo.wifiIP = wifiAddress
        localIPInfo.wifiMask = wifiNetMask
        localIPInfo.cellularIP = cellAddress
        localIPInfo.cellularMask = cellNetMask
        if wifiAddress != nil {
            localIPInfo.currentInterfaceIP = wifiAddress
            localIPInfo.currentInterfaceMask = wifiNetMask
            return localIPInfo
        }
        localIPInfo.currentInterfaceIP = cellAddress
        localIPInfo.currentInterfaceMask = cellNetMask
        return localIPInfo
    }
    //Get IP segment by subnet mask
    public class func getIPNetworkSegment(ip: String, subnetMask: String) -> String? {
        if !ip.contains(".") || !subnetMask.contains(".") {
            return nil
        }
        
        let ipArray: Array = CommonTools.fixIPFormate(ip: ip).components(separatedBy: ".")
        let maskArray: Array = CommonTools.fixIPFormate(ip: subnetMask).components(separatedBy: ".")
        
        if ipArray.count != 4 ||
            maskArray.count != 4 {
            return nil
        }
        
        var segmentArray: Array = [String]()
        
        for i in 0..<ipArray.count {
            let ipOctet: Int = Int(ipArray[i]) ?? 0
            let maskOctet: Int = Int(maskArray[i]) ?? 0
            let segmentOctet = (ipOctet & maskOctet)
            segmentArray.append(String(segmentOctet))
        }
        return segmentArray.joined(separator: ".")
    }
    //Get IP broadcastIP by subnet mask
    public class func getIPBroadcast(ip: String, WithSubnetMask subnetMask: String) -> String? {
        if !ip.contains(".") || !subnetMask.contains(".") {
            return nil
        }
        
        let ipArray: Array = CommonTools.fixIPFormate(ip: ip).components(separatedBy: ".")
        let maskArray: Array = CommonTools.fixIPFormate(ip: subnetMask).components(separatedBy: ".")
        
        if ipArray.count != 4 ||
            maskArray.count != 4 {
            return nil
        }
        
        var broadcastArray : Array = [String]();
        for i in 0..<ipArray.count {
            let ipOctet: Int = Int(ipArray[i]) ?? 0
            let maskOctet: Int = Int(maskArray[i]) ?? 0
            let broadcastOctet = (ipOctet | (255 - maskOctet))
            broadcastArray.append(String(broadcastOctet))
        }
        return broadcastArray.joined(separator: ".")
    }
    
    class func getDecFromHex(hex: String) -> UInt64 {
        var result: UInt64 = 0
        let scanner: Scanner = Scanner.init(string: hex)
        scanner.scanHexInt64(&result)
        return result
    }
    
    public class func getIPV6FromMac(mac: String, ForTest forTest: Bool) -> String {
        if mac.count == 0 {
            return ""
        }
        
        var macArray: Array = [String]()
        var macValueArray: Array = [UInt64]()
        
        for ch in mac {
            if ch != ":" {
                macArray.append(String(ch))
            }
        }
        
        if macArray.count != 12 {
            return ""
        }
        
        var x: Int = 0
        while x < macArray.count {
            var macValue: UInt64 = CommonTools.getDecFromHex(hex: macArray[x]) * 16
            x+=1
            macValue = macValue + CommonTools.getDecFromHex(hex: macArray[x])
            x+=1
            macValueArray.append(macValue)
        }
        
        var ipv6String : String
        if forTest {
            ipv6String = "fc00::"
        } else {
            ipv6String = "fe80::"
        }
        
        if 0 == macValueArray[0] ^ 0x02 {
            if 0 != macValueArray[1] {
                ipv6String.append("\(macValueArray[1]):")
            }
        }else{
            ipv6String.append(String(format: "%x%02x:", macValueArray[0] ^ 0x02, macValueArray[1]))
        }
        
        if 0 == macValueArray[2] {
            ipv6String.append(String(format: "ff:fe%02x:", macValueArray[3]))
        }else {
            ipv6String.append(String(format: "%xff:fe%02x:", macValueArray[2], macValueArray[3]))
        }
        
        if 0 == macValueArray[4] {
            if 0 == macValueArray[5] {
                ipv6String.append("0")
            }else {
                ipv6String.append(String(macValueArray[5]))
            }
        }else {
            ipv6String.append(String(format: "%x%02x", macValueArray[4], macValueArray[5]))
        }
        
        return ipv6String
    }
    
    //MARK: - About Image
    //Resize image
    public class func imageWithImage(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x:0, y:0, width:newSize.width, height:newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext()
        return newImage
    }
    
    public class func imageWithImage(image: UIImage, scaledWithPercent percent: CGFloat) -> UIImage {
        let newSize = CGSize(width: image.size.width * percent, height: image.size.height * percent)
        return CommonTools.imageWithImage(image: image, scaledToSize: newSize)
    }
    //Filter image to circcle
    public class func circleImage(image: UIImage, withParm inset: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.clear.cgColor)
        let rect: CGRect = CGRect(x: inset, y: inset, width: image.size.width-inset*2.0, height: image.size.height-inset*2.0)
        context.addEllipse(in: rect)
        context.clip()
        
        image.draw(in: rect)
        context.addEllipse(in: rect)
        context.strokePath()
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    //Crop image with rect
    public class func imageByCropping(imageToCrop: UIImage, toRect rect: CGRect) -> UIImage {
        let tmp: CGImage = imageToCrop.cgImage!.cropping(to: rect)!
        let timage: UIImage = UIImage(cgImage: tmp)
        return timage
    }
    //Create image with color and size
    public class func imageWithColor(color: UIColor, Size size: CGSize) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    //Create circle image with color and size
    public class func circleImageWIthColor(color: UIColor, Size size: CGSize) -> UIImage {
        let colorImage: UIImage = CommonTools.imageWithColor(color: color, Size: size)
        return CommonTools.circleImage(image: colorImage, withParm: 0)
    }
    //Get UIView snapshot
    public class func snapshot(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
#if __IPHONE_13_0
    //Invert Image
    public class func invertImageWithCIFilterForImage(image: UIImage) -> UIImage {
        var coreImage: CIImage = CIImage.init(image: image)
        var filter: CIFilter = CIFilter.init(name: "CIColorInvert")
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        var resultCore: CIImage = filter.value(forKey: kCIOutputImageKey)
        
        // Convert the filter output back into a UIImage.
        var context: CIContext = CIContext.init(options: nil);
        var resultRef: CGImageRef = context.createCGImage(resultCore, from: resultCore.extent)
        var result: UIImage = UIImage.init(cgImage: resultRef)
        return result
    }
    public class func changeHueWithCIFilterForImage(source: UIImage, ByAngel angle: Int) -> UIImage {
        // Create a Core Image version of the image.
        var sourceCore = CIImage.init(cgImage: source.cgImage)
        
        // Apply a CIHueAdjust filter
        var deltaHueRadians: Float = GLKMathDegreesToRadians(angle)
        var hueAdjust: CIFilter = CIFilter.init(name: "CIHueAdjust")
        hueAdjust.setDefaults()
        hueAdjust.setValue(sourceCore, forKey: kCIInputImageKey)
        hueAdjust.setValue(deltaHueRadians, forKey: kCIInputAngleKey)
        var resultCore = hueAdjust.value(forKey: kCIOutputImageKey)
        
        // Convert the filter output back into a UIImage.
        var context: CIContext = CIContext.init(options: nil);
        var resultRef: CGImageRef = context.createCGImage(resultCore, from: resultCore.extent)
        var result: UIImage = UIImage.init(cgImage: resultRef)
        return result
    }
    public class func changeBrightnessWithCIFilterForImage(source: UIImage, ByBrightness brightness: Float) -> UIImage {
        // Create a Core Image version of the image.
        var sourceCore = CIImage.init(cgImage: source.cgImage)
        
        var deltaHueRadians: Float = GLKMathDegreesToRadians(angle)
        var hueAdjust: CIFilter = CIFilter.init(name: "CIColorControls")
        hueAdjust.setValue(sourceCore, forKey: kCIInputImageKey)
        hueAdjust.setValue(brightness, forKey: kCIInputBrightnessKey)
        var resultCore = hueAdjust.value(forKey: kCIOutputImageKey)
        
        // Convert the filter output back into a UIImage.
        var context: CIContext = CIContext.init(options: nil);
        var resultRef: CGImageRef = context.createCGImage(resultCore, from: resultCore.extent)
        var result: UIImage = UIImage.init(cgImage: resultRef)
        return result
    }
#endif
    //MARK: - About String
    public class func truncateBackItemTitle(barItemTitle: String, withMainTitle mainTitle: String) ->String {
        let width: CGFloat = CommonTools.getScreenSize().width
        let maxLength: Int = Int(roundf(Float(width)*0.048))
        let leftLength: Int = maxLength - Int(roundf(Float(mainTitle.count)/2.0))
        if barItemTitle.count > leftLength {
            let shortSting: String = String(barItemTitle.prefix(leftLength-3))
            return "\(shortSting)..."
        }
        return barItemTitle
    }
    //MARK: - About Convert
    public class func decToBinary(decInt: Int) -> String {
        var string: String = ""
        var x: Int = decInt
        repeat {
            string = "\(x&1)" + string
            x>>=1
        } while (x > 0)
        return string
    }
    public class func getJSONStringFromJSONObject(jsonObject: Any) -> String {
        if !JSONSerialization.isValidJSONObject(jsonObject) {
            return ""
        }
        do {
            let jsonData: Data = try JSONSerialization.data(withJSONObject: jsonObject, options: []) // first of all convert json to the data
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? "" // the data will be converted to the string
        } catch let jsonError {
            print(jsonError)
            return ""
        }
    }
    //MARK: - About Format Check
    //Check is numeric value
    public class func checkIsAllDigits(str: String) -> Bool {
        let noNumbers : CharacterSet = CharacterSet.decimalDigits.inverted
        return str.rangeOfCharacter(from: noNumbers) == nil
    }
    //Check UID format valid
    public class func checkUIDFormateValid(uid: String) -> Bool {
        if uid.count != 7 {
            return false
        }
        if uid.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count != 7 {
            return false
        }
        if  uid.contains(" "){
            return false
        }
        if NSURL.init(string: "\(uid).domain.com") == nil {
            return false
        }
        if !CommonTools.regularCheck(pattern: "^[\\x00-\\x7F]+$", checkStr: uid) {
            return false
        }
        if uid == "0000000" {
            return false
        }
        return true
    }
    //Check E-mail format vaild
    public class func checkEmailFormateValid(mail: String) -> Bool {
        let emailRegex: String = "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}"
        let emailTest: NSPredicate = NSPredicate(format: "SELF MATCHES \(emailRegex)")
        return emailTest.evaluate(with: mail)
    }
    //Check SSID valid
    public class func checkSSIDValid(ssid: String) -> Bool {
        let tmpString: String = ssid.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if tmpString.count == 0 {
            return false
        }
        
        if tmpString.count > 32 {
            return false
        }
        
        let tmpData: Data = tmpString.data(using: .utf8)!
        if tmpData.count == 0 {
            return false
        }
        
        if tmpData.count > 32 {
            return false
        }
        
        return CommonTools.regularCheck(pattern: "^[\\x00-\\x7F]+$", checkStr: tmpString)
    }
    //Check WPA key valid
    public class func checkWPAKeyValid(key: String) -> WPAInvalidType {
        if key.count < 8 {
            return WPAInvalidType.InvalidWPALengthType
        }
        
        if key.count > 64 {
            return WPAInvalidType.InvalidWPALengthType
        }
        
        if key.count == 64 {
            if !CommonTools.regularCheck(pattern: "^([a-f]|[A-F]|[0-9]){64}$", checkStr: key) {
                return WPAInvalidType.InvalidWPAHEXType
            }
        }else {
            if !CommonTools.regularCheck(pattern: "^[\\x00-\\x7F]+$", checkStr: key) {
                return WPAInvalidType.InvalidWPAASCIIType
            }
        }
        
        return WPAInvalidType.ValidWPAType
    }
    //Check WEP key valid
    public class func checkWEPKeyValid(key: String) -> WEPInvalidType {
        var type: WEPInvalidType = WEPInvalidType.ValidWEPType
        
        if key.count == 5 || key.count == 13 || key.count == 16 {
            if !CommonTools.regularCheck(pattern: "^(\\d|\\D){\(key.count)}$", checkStr: key) {
                type = WEPInvalidType.InvalidWEPASCIIType
            }
        }else if key.count == 10 || key.count == 26 || key.count == 32 {
            if !CommonTools.regularCheck(pattern: "[a-fA-F0-9]{\(key.count)}", checkStr: key) {
                type = WEPInvalidType.InvalidWEPHEXType
            }
        }else{
            type = WEPInvalidType.InvalidWEPLengthType
        }
        
        return type
    }
    class func checkSubnetMaskBinary(subnetMaskArray: Array<String>) -> Bool {
        if subnetMaskArray.count != 4 {
            return false
        }
        
        var binString: String = ""
        for i in 0..<4 {
            if !CommonTools.checkIsAllDigits(str: subnetMaskArray[i]) {
                return false
            }
            
            let num: Int = Int(subnetMaskArray[i]) ?? 0
            if num < 0 || num > 255  {
                return false
            }
            
            var zeroString = ""
            let numBinString: String = CommonTools.decToBinary(decInt: num)
            if numBinString.count < 8 {
                for _ in 0..<(8-numBinString.count) {
                    zeroString.append("0")
                }
            }
            binString.append(zeroString)
            binString.append(numBinString)
        }
        
        if binString.count == 0 {
            return false
        }
        
        return CommonTools.regularCheck(pattern: "^1*0*$", checkStr: binString)
    }
    //Check subnet mask valid
    public class func checkSubnetMaskValid(subnetMask: String) ->Bool {
        if CommonTools.checkHasFullWidthWord(string: subnetMask) {
            return false
        }
        
        let strArray: Array = subnetMask.components(separatedBy: ".")
        if !CommonTools.checkSubnetMaskBinary(subnetMaskArray: strArray) {
            return false
        }
        return CommonTools.regularCheck(pattern: "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}0", checkStr: CommonTools.fixIPFormate(ip: subnetMask))
    }
    //Check Server Gateway
    public class func checkServerGatewayValid(serverGateway: String) -> Bool {
        if serverGateway.count == 0 {
            return false
        }
        
        if serverGateway == "0.0.0.0" {
            return false
        }
        
        if serverGateway == "127.0.0.1" {
            return false
        }
        
        if NSURL.init(string: serverGateway) == nil {
            return false
        }
        
        if !CommonTools.checkStaticIPInfo(ip: serverGateway, Type: StaticIPInfoType.StaticIPInfoGatewayType)
            || CommonTools.checkHostnameValid(hostname: serverGateway)
        {
            return false;
        }
        
        return true
    }
    //Check Port valid
    public class func checkPortValid(port: Int, MMinValue minValue: Int, MaxValue maxValue: Int) -> Bool {
        if port > maxValue || port < minValue {
            return false
        }
        return true
    }
    //Check IPAddress valid
    public class func checkIPV4AddressValid(ipaddr: String) -> Bool {
        if CommonTools.checkHasFullWidthWord(string: ipaddr) {
            return false
        }
        return CommonTools.regularCheck(pattern: "^(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5]).(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5]).(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5]).(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5])$", checkStr: CommonTools.fixIPFormate(ip: ipaddr));
    }
    public class func checkDomainValid(domain: String) -> Bool {
        var pattern = "((?:(http|https|Http|Https|rtsp|Rtsp):\\/\\/(?:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)"
        pattern.append("\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_")
        pattern.append("\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,25})?\\@)?)?")
        pattern.append("((?:(?:[\(GOOD_IRI_CHAR)][\(GOOD_IRI_CHAR)\\-]{0,64}\\.)+") // named host
        pattern.append(TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL)
        pattern.append("|(?:(?:25[0-5]|2[0-4]") // or ip address
        pattern.append("[0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(?:25[0-5]|2[0-4][0-9]")
        pattern.append("|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1]")
        pattern.append("[0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}")
        pattern.append("|[1-9][0-9]|[0-9])))")
        pattern.append("(?:\\:\\d{1,5})?)") // plus option port number
        pattern.append("(\\/(?:(?:[a-zA-Z0-9\\;\\/\\?\\:\\@\\&\\=\\#\\~") // plus option query params
        pattern.append("\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_])|(?:\\%[a-fA-F0-9]{2}))*)?")
        pattern.append("(?:\\b|$)") // and finally, a word boundary or end of input.  This is to stop foo.sure from matching as foo.su
        return CommonTools.regularCheck(pattern: pattern, checkStr: domain)
    }
    public class func checkStaticIPInfo(ip: String, Type type: StaticIPInfoType) -> Bool {
        if ip.count == 0 {
            return false
        }
        
        if CommonTools.checkHasFullWidthWord(string: ip) {
            return false
        }
        
        if CommonTools.fixIPFormate(ip: ip) == "0.0.0.0" {
            switch type {
            case .StaticIPInfoIPType:
                return false
            case .StaticIPInfoGatewayType:
                return true
            }
        }
        
        let numArray = CommonTools.fixIPFormate(ip: ip).components(separatedBy: ".")
        if numArray.count != 4 {
            return false
        }
        
        for i in 0..<numArray.count {
            if CommonTools.checkIsAllDigits(str: numArray[i]) {
                return false
            }
            
            let digit: Int = Int(numArray[i]) ?? -1
            if digit < 0 {
                return false
            }
            if digit > 255 {
                return false
            }
            
            if i == 0 {
                if digit < 1 || digit > 223 {
                    return false
                }
            }
            
            if i == 3 {
                if digit < 1 || digit > 254 {
                    return false
                }
            }
        }
        if CommonTools.checkIPV4AddressValid(ipaddr: ip) {
            return false
        }
        if CommonTools.getIPNetworkSegment(ip: "127.0.0.1", subnetMask: "255.0.0.0") == CommonTools.getIPNetworkSegment(ip: ip, subnetMask: "255.0.0.0") {
            return false
        }
        if CommonTools.getIPNetworkSegment(ip: "169.254.0.1", subnetMask: "255.255.0.0") == CommonTools.getIPNetworkSegment(ip: ip, subnetMask: "255.255.0.0") {
            return false
        }
        if CommonTools.regularCheck(pattern: "^(22[4-9]|2[3-4][0-9]|25[0-5])\\.(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5])\\.(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5])\\.(\\d{1,2}|1\\d\\d|2[0-4]\\d|25[0-5])$", checkStr: ip) {
            return false
        }
        return true
    }
    //Check Hostname Valid
    public class func checkHostnameValid(hostname: String) -> Bool {
        return CommonTools.regularCheck(pattern: "^[a-zA-Z0-9]\\w{0,30}$", checkStr: hostname)
    }
    //Check Has Full Width Word
    public class func checkHasFullWidthWord(string: String) -> Bool {
        return CommonTools.regularCheck(pattern: "[^\\x00-\\xff]", checkStr: string)
    }
    //Regular check function
    public class func regularCheck(pattern: String, checkStr: String) -> Bool {
        if checkStr.count == 0 {
            return false
        }
        let trimCheckStr: String = checkStr.trimmingCharacters(in: CharacterSet.whitespaces)
        if trimCheckStr.count == 0 {
            return false
        }
        let pred: NSPredicate = NSPredicate(format: "SELF MATCHES \(pattern)")
        return pred.evaluate(with: checkStr)
    }
    class func fixIPFormate(ip : String) -> String {
        //    example: 10.0.053.122 -- replace to -- > 10.0.53.122
        let tokArray: Array = ip.components(separatedBy: ".")
        var retString : String = ""
        for i in 0..<tokArray.count {
            let lastOneString: String = (i == tokArray.count-1) ? "" : "."
            var tok: String = tokArray[i]
            if tok.count >= 2 {
                if CommonTools.checkIsAllDigits(str: tok)
                    && tok.hasPrefix("0") {
                    tok = String(describing: Int(tok))
                }
            }
            retString += tok
            retString += lastOneString
        }
        return retString
    }
    //MARK: - About Web View
    //Load file with file name(Auto check type with file extension)
    public class func loadDocument(documentName: String, inWKView documentWebView: WKWebView) {
        DispatchQueue.main.async {
            let path: String = Bundle.main.path(forResource: documentName, ofType: nil) ?? ""
            do {
                let html: String = try String.init(contentsOfFile: path, encoding: .utf8)
                let url: URL = URL.init(fileURLWithPath: path)
                let headerString: String = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
                documentWebView.loadHTMLString(headerString+html, baseURL: url)
            } catch {
                print(error)
            }
        }
    }
    //Load file with file name and file type
    public class func loadDocument(documentName: String, withType type: String, inWKView documentWebView: WKWebView) {
        DispatchQueue.main.async {
            let path: String = Bundle.main.path(forResource: documentName, ofType: type) ?? ""
            do {
                let html: String = try String.init(contentsOfFile: path, encoding: .utf8)
                let url: URL = URL.init(fileURLWithPath: path)
                let headerString: String = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
                documentWebView.loadHTMLString(headerString+html, baseURL: url)
            } catch {
                print(error)
            }
        }
    }
    //Load file with file path
    public class func loadDocumentPath(path: String, inWKView documentWebView: WKWebView) {
        DispatchQueue.main.async {
            do {
                let html: String = try String.init(contentsOfFile: path, encoding: .utf8)
                let url: URL = URL.init(fileURLWithPath: path)
                let headerString: String = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
                documentWebView.loadHTMLString(headerString+html, baseURL: url)
            } catch {
                print(error)
            }
        }
    }
    //MARK: - About Version Number
    //Check version is newer than standardVersion
    public class func checkVersionNumber(version: String, isNewerThan standardVersion: String) -> Bool {
        if standardVersion.compare(version, options: .numeric) == .orderedAscending {
            return true
        }
        return false
    }
    //Check version is lower than standardVersion
    public class func checkVersionNumber(version: String, isLowerThan standardVersion: String) -> Bool {
        if standardVersion.compare(version, options: .numeric) == .orderedDescending {
            return true
        }
        return false
    }
    //Check version is same with standardVersion
    public class func checkVersionNumber(version: String, isSameWith standardVersion: String) -> Bool {
        if standardVersion.compare(version, options: .numeric) == .orderedSame {
            return true
        }
        return false
    }
}
