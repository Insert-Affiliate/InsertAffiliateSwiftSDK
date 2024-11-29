import Foundation
import UIKit
import InAppPurchaseLib

public struct InsertAffiliateSwift {
    private static var companyCode: String?

    public static func initialize(companyCode: String?) {
        if let code = companyCode, !code.isEmpty {
            self.companyCode = code
            print("[Insert Affiliate] SDK initialised with company code: \(code)")
        } else {
            print("[Insert Affiliate] SDK initialised without a company code.")
        }
    }
    
    private static func isCompanyCodeSet() -> Bool {
        return companyCode != nil
    }

    public static func enterShortCode(shortCode: String) {
        let capitalisedShortCode = shortCode.uppercased()

        guard capitalisedShortCode.count == 10 else {
            print("[Insert Affiliate] Error: Short code must be exactly 10 characters long.")
            return
        }

        // Check if the short code contains only letters and numbers
        let alphanumericSet = CharacterSet.alphanumerics
        let isValidShortCode = capitalisedShortCode.unicodeScalars.allSatisfy { alphanumericSet.contains($0) }
        guard isValidShortCode else {
            print("[Insert Affiliate] Error: Short code must contain only letters and numbers.")
            return
        }

        // If all checks pass, set the Insert Affiliate Identifier
        setInsertAffiliateIdentifier(referringLink: capitalisedShortCode)

        // Return and print the Insert Affiliate Identifier
        if let insertAffiliateIdentifier = returnInsertAffiliateIdentifier() {
            print("[Insert Affiliate] Successfully set affiliate identifier: \(insertAffiliateIdentifier)")
        } else {
            print("[Insert Affiliate] Failed to set affiliate identifier.")
        }
    }

    internal static func returnShortUniqueDeviceID() -> String {
       if let savedShortUniqueDeviceID = UserDefaults.standard.string(forKey: "shortUniqueDeviceID") {
           return savedShortUniqueDeviceID
       } else {
           let shortUniqueDeviceID = self.storeAndReturnShortUniqueDeviceID()
           return shortUniqueDeviceID
       }
    }
    
    internal static func storeAndReturnShortUniqueDeviceID() -> String {
        let uuid = UUID().uuidString
        let hashed = uuid.hashValue
        let shortUniqueDeviceID = String(format: "%06X", abs(hashed) % 0xFFFFFF)
        UserDefaults.standard.set(shortUniqueDeviceID, forKey: "shortUniqueDeviceID")
        return shortUniqueDeviceID
    }
    
    public static func setInsertAffiliateIdentifier(referringLink: String) {
        // TODO: if its not a short code, call out to our backend & check if its a long referrring link that can be converted to a short code...
        
        let insertAffiliateIdentifier = "\(referringLink)/\(returnShortUniqueDeviceID())"
        UserDefaults.standard.set(insertAffiliateIdentifier, forKey: "insertAffiliateIdentifier")
    }
    
    public static func returnInsertAffiliateIdentifier() -> String? {
        return UserDefaults.standard.string(forKey: "insertAffiliateIdentifier")
    }
    
    public static func reinitializeIAP(iapProductsArray: [IAPProduct], validatorUrlString: String) {
        InAppPurchase.stop()

        if let applicationUsername = returnInsertAffiliateIdentifier() {
            InAppPurchase.initialize(
                iapProducts: iapProductsArray,
                validatorUrlString: validatorUrlString,
                applicationUsername: applicationUsername
            )
        } else {
            InAppPurchase.initialize(
                iapProducts: iapProductsArray,
                validatorUrlString: validatorUrlString
            )
        }
    }

    // MARK: Offer Code
    internal static func removeSpecialCharacters(from string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return string.unicodeScalars.filter { allowedCharacters.contains($0) }.map { Character($0) }.reduce("") { $0 + String($1) }
    }

    internal static func fetchOfferCode(affiliateLink: String, completion: @Sendable @escaping (String?) -> Void) {
        guard let encodedAffiliateLink = affiliateLink.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("[Insert Affiliate] Failed to encode affiliate link")
            completion(nil)
            return
        }

        let offerCodeUrlString = "https://api.insertaffiliate.com/v1/affiliateReturnOfferCode/" + encodedAffiliateLink
        
        guard let offerCodeUrl = URL(string: offerCodeUrlString) else {
            print("[Insert Affiliate] Invalid offer code URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: offerCodeUrl) { data, response, error in
            if let error = error {
                print("[Insert Affiliate] Error fetching offer code: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("[Insert Affiliate] No data received")
                completion(nil)
                return
            }
            
            if let rawOfferCode = String(data: data, encoding: .utf8) {
                let offerCode = removeSpecialCharacters(from: rawOfferCode)
                
                if offerCode == "errorofferCodeNotFound" ||
                    offerCode == "errorAffiliateoffercodenotfoundinanycompany" ||
                    offerCode == "errorAffiliateoffercodenotfoundinanycompanyAffiliatelinkwas" ||
                    offerCode == "Routenotfound" {
                        print("[Insert Affiliate] Offer Code Not Found")
                        completion(nil)
                } else {
                    print("[Insert Affiliate] Offer Code received: \(offerCode)")
                    completion(offerCode)
                }
            } else {
                print("[Insert Affiliate] Failed to decode Offer Code")
                completion(nil)
            }
        }
        
        task.resume()
    }

    internal static func openRedeemURL(with offerCode: String, offerCodeUrlId: String) {
       let redeemUrlString = "https://apps.apple.com/redeem?ctx=offercodes&id=\(offerCodeUrlId)&code=\(offerCode)"
       if let redeemUrl = URL(string: redeemUrlString) {
           DispatchQueue.main.async {
               UIApplication.shared.open(redeemUrl, options: [:]) { success in
                   if success {
                       print("[Insert Affiliate] Successfully opened redeem URL")
                   } else {
                       print("[Insert Affiliate] Failed to open redeem URL")
                   }
               }
           }
       } else {
           print("[Insert Affiliate] Invalid redeem URL")
       }
    }
    
    public static func fetchAndConditionallyOpenUrl(affiliateLink: String, offerCodeUrlId: String) {
        fetchOfferCode(affiliateLink: affiliateLink) { offerCode in
            if let offerCode = offerCode {
                openRedeemURL(with: offerCode, offerCodeUrlId: offerCodeUrlId)
            } else {
                print("[Insert Affiliate] No valid offer code found.")
            }
        }
    }

    public static func trackEvent(eventName: String) {
        guard let deepLinkParam = returnInsertAffiliateIdentifier() else {
            print("[Insert Affiliate] No affiliate identifier found. Please set one before tracking events.")
            return
        }

        let payload: [String: Any] = [
            "eventName": eventName,
            "deepLinkParam": deepLinkParam
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("[Insert Affiliate] Failed to encode event payload")
            return
        }

        let apiUrlString = "https://api.insertaffiliate.com/v1/trackEvent"
        guard let apiUrl = URL(string: apiUrlString) else {
            print("[Insert Affiliate] Invalid API URL")
            return
        }

        // Create and configure the request
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Insert Affiliate] Error tracking event: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Insert Affiliate] No response received")
                return
            }

            // Check for a successful response
            if httpResponse.statusCode == 200 {
                print("[Insert Affiliate] Event tracked successfully")
            } else {
                print("[Insert Affiliate] Failed to track event with status code: \(httpResponse.statusCode)")
            }
        }

        task.resume()
    }
}
