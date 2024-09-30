// TODO: Write important parts of this...
// - https://medium.com/swlh/building-an-sdk-for-ios-in-swift-688d13f0a6fb

import Foundation

public struct InsertAffiliateSwift {
    public static func getShortUniqueDeviceID() -> String {
       if let savedDeviceID = UserDefaults.standard.string(forKey: "shortUniqueDeviceID") {
           return savedDeviceID
       } else {
           let uuid = UUID().uuidString
           let hashed = uuid.hashValue
           let uniqueDeviceIDshort = String(format: "%06X", abs(hashed) % 0xFFFFFF)
           UserDefaults.standard.set(uniqueDeviceIDshort, forKey: "shortUniqueDeviceID")

           return uniqueDeviceIDshort
       }
    }
    
    public static func setInsertAffiliateIdentifier(referringLink: String) {
        let insertAffiliateIdentifier = "\(referringLink)/\(getShortUniqueDeviceID())"
        UserDefaults.standard.set(insertAffiliateIdentifier, forKey: "insertAffiliateIdentifier")
    }
    
    public static func getInsertAffiliateIdentifier() -> String? {
        return UserDefaults.standard.string(forKey: "insertAffiliateTrackerKey")
    }
}
