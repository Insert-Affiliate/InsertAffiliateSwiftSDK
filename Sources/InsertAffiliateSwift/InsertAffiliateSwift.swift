import Foundation
import UIKit

@available(iOS 13.0.0, *)
actor InsertAffiliateState {
    private var companyCode: String?
    private var isInitialized = false

    func initialize(companyCode: String?) throws {
        guard !isInitialized else {
            throw NSError(domain: "InsertAffiliateSwift", code: 1, userInfo: [NSLocalizedDescriptionKey: "SDK is already initialized."])
        }

        if let code = companyCode, !code.isEmpty {
            self.companyCode = code
            isInitialized = true
            print("[Insert Affiliate] SDK initialized with company code: \(code)")
        } else {
            self.companyCode = nil
            isInitialized = true
            print("[Insert Affiliate] SDK initialized without a company code.")
        }
    }

    func getCompanyCode() -> String? {
        return companyCode
    }

    func reset() {
        companyCode = nil
        isInitialized = false
        print("[Insert Affiliate] SDK has been reset.")
    }
}

public struct InsertAffiliateSwift {
    @available(iOS 13.0.0, *)
    private static let state = InsertAffiliateState()

    public static func initialize(companyCode: String?) {
        guard #available(iOS 13.0, *) else {
            print("[Insert Affiliate] This SDK requires iOS 13.0 or newer.")
            return
        }

        Task {
            do {
                try await state.initialize(companyCode: companyCode)
                getOrCreateUserAccountToken()
            } catch {
                print("[Insert Affiliate] Error initializing SDK: \(error.localizedDescription)")
            }
        }
    }

    // For users using App Store Receipts directly without a Receipt Validator
    private static func getOrCreateUserAccountToken() -> UUID {
        if let storedUUIDString = UserDefaults.standard.string(forKey: "appAccountToken"),
           let storedUUID = UUID(uuidString: storedUUIDString) {
            return storedUUID
        } else {
            let newUUID = UUID()
            UserDefaults.standard.set(newUUID.uuidString, forKey: "appAccountToken")
            return newUUID
        }
    }

    // Function to return the stored UUID for users using App Store Receipts directly without a Receipt Validator
    public static func returnUserAccountTokenAndStoreExpectedTransaction() async -> UUID? {
        // 1: Check if they have an affiliate assigned before storing the transaction
        guard let insertAffiliateIdentifier = returnInsertAffiliateIdentifier() else {
            print("[Insert Affiliate] No affiliate stored - not saving expected transaction")
            return nil
        }
            
        if let storedUUIDString = UserDefaults.standard.string(forKey: "appAccountToken"),
           let storedUUID = UUID(uuidString: storedUUIDString) {
                await storeExpectedAppStoreTransaction(userAccountToken: storedUUID)
                return storedUUID;
        } else {
            print("[Insert Affiliate] No valid user account token found, skipping expected transaction storage.")
        }
        return nil
    }

    public static func setShortCode(shortCode: String) {
        let capitalisedShortCode = shortCode.uppercased()

        guard capitalisedShortCode.count >= 3 && capitalisedShortCode.count <= 25 else {
            print("[Insert Affiliate] Error: Short code must be between 3 and 25 characters long.")
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
        storeInsertAffiliateIdentifier(referringLink: capitalisedShortCode)

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
    
    public static func setInsertAffiliateIdentifier(
        referringLink: String,
        completion: @escaping @Sendable (String?) -> Void
    ) {
        if #available(iOS 13.0, *) {
            Task {
                guard let companyCode = await state.getCompanyCode(), !companyCode.isEmpty else {
                    print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
                    completion(nil)
                    return
                }

                // Check if the referringLink is already a short code
                if isShortCode(referringLink) {
                    print("[Insert Affiliate] Referring link is already a short code")
                    storeInsertAffiliateIdentifier(referringLink: referringLink)
                    completion(referringLink)
                    return
                }

                guard let encodedAffiliateLink = referringLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    print("[Insert Affiliate] Failed to encode affiliate link")
                    storeInsertAffiliateIdentifier(referringLink: referringLink)
                    completion(nil)
                    return
                }

                let urlString = "https://api.insertaffiliate.com/V1/convert-deep-link-to-short-link?companyId=\(companyCode)&deepLinkUrl=\(encodedAffiliateLink)"

                guard let url = URL(string: urlString) else {
                    print("[Insert Affiliate] Invalid URL")
                    storeInsertAffiliateIdentifier(referringLink: referringLink)
                    completion(nil)
                    return
                }

                // Create the GET request
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        storeInsertAffiliateIdentifier(referringLink: referringLink)
                        print("[Insert Affiliate] Error: \(error.localizedDescription)")
                        completion(nil)
                        return
                    }

                    guard let data = data else {
                        storeInsertAffiliateIdentifier(referringLink: referringLink)
                        print("[Insert Affiliate] No data received")
                        completion(nil)
                        return
                    }

                    do {
                        // Parse JSON response
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                            let shortLink = json["shortLink"] as? String {
                            print("[Insert Affiliate] Short link received: \(shortLink)")
                            storeInsertAffiliateIdentifier(referringLink: shortLink)
                            completion(shortLink)
                        } else {
                            storeInsertAffiliateIdentifier(referringLink: referringLink)

                            print("[Insert Affiliate] Unexpected JSON format")
                            completion(nil)
                        }
                    } catch {
                        storeInsertAffiliateIdentifier(referringLink: referringLink)
                        print("[Insert Affiliate] Failed to parse JSON: \(error.localizedDescription)")
                        completion(nil)
                    }
                }

                task.resume()
            }
        }
    }

    private static func isShortCode(_ link: String) -> Bool {
        // Check if the link is 10 characters long and contains only letters and numbers
        let regex = "^[a-zA-Z0-9]{3,25}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: link)
    }

    public static func storeInsertAffiliateIdentifier(referringLink: String) {
        let insertAffiliateIdentifier = "\(referringLink)-\(returnShortUniqueDeviceID())"
        UserDefaults.standard.set(insertAffiliateIdentifier, forKey: "insertAffiliateIdentifier")
        
        // Automatically fetch and store offer code ONLY if it's a short code
        if isShortCode(referringLink) {
            retrieveAndStoreOfferCode(affiliateLink: referringLink) { offerCode in
                if let offerCode = offerCode {
                    print("[Insert Affiliate] Automatically retrieved and stored offer code: \(offerCode)")
                }
            }
        }
    }
    
    public static func returnInsertAffiliateIdentifier() -> String? {
        return UserDefaults.standard.string(forKey: "insertAffiliateIdentifier")
    }
    
    public static var OfferCode: String? {
        return UserDefaults.standard.string(forKey: "OfferCode")
    }

    // MARK: Offer Code
    internal static func removeSpecialCharacters(from string: String) -> String {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "_")
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
                    offerCode == "errorOffercodenotfound" ||
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

    private static func retrieveAndStoreOfferCode(affiliateLink: String, completion: @escaping @Sendable (String?) -> Void = { _ in }) {
        fetchOfferCode(affiliateLink: affiliateLink) { offerCode in
            if let offerCode = offerCode {
                UserDefaults.standard.set(offerCode, forKey: "OfferCode")
                print("[Insert Affiliate] Offer code stored: \(offerCode)")
                completion(offerCode)
            } else {
                print("[Insert Affiliate] No valid offer code found.")
                completion(nil)
            }
        }
    }

    public static func trackEvent(eventName: String) async {
        guard let deepLinkParam = returnInsertAffiliateIdentifier() else {
            print("[Insert Affiliate] No affiliate identifier found. Please set one before tracking events.")
            return
        }

        guard let companyCode = await state.getCompanyCode(), !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return
        }

        let payload: [String: Any] = [
            "eventName": eventName,
            "deepLinkParam": deepLinkParam,
            "companyId": companyCode
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

    public static func storeExpectedAppStoreTransaction(userAccountToken: UUID) async {
        guard let companyCode = await state.getCompanyCode() else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return
        }

        guard let shortCode = returnInsertAffiliateIdentifier() else {
            print("[Insert Affiliate] No affiliate identifier found. Please set one before tracking events.")
            return
        }

        // ✅ Convert Date to String
        let dateFormatter = ISO8601DateFormatter()
        let storedDateString = dateFormatter.string(from: Date())

        // ✅ Convert UUID to String
        let uuidString = userAccountToken.uuidString

        // Set the params passed as the body of the request
        let payload: [String: Any] = [
            "UUID": uuidString,
            "companyCode": companyCode,
            "shortCode": shortCode,
            "storedDate": storedDateString
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("[Insert Affiliate] Failed to encode expected transaction payload")
            return
        }

        let apiUrlString = "https://api.insertaffiliate.com/v1/api/app-store-webhook/create-expected-transaction"
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
                print("[Insert Affiliate] Error storing expected transaction: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Insert Affiliate] No response received")
                return
            }

            // Check for a successful response
            if httpResponse.statusCode == 200 {
                print("[Insert Affiliate] Expected transaction stored successfully")
            } else {
                // Check the message first, if its that the transaction already exists, respond with 200
                print("[Insert Affiliate] Failed to store expected transaction with status code: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }
}
