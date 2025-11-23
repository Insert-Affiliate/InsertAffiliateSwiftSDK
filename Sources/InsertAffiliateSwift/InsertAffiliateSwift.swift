import Foundation
import UIKit
import Network

@available(iOS 13.0.0, *)
actor InsertAffiliateState {
    private var companyCode: String?
    private var isInitialized = false
    private var verboseLogging = false
    private var insertLinksEnabled = false
    private var insertLinksClipboardEnabled = false
    private var affiliateAttributionActiveTime: TimeInterval?

    func initialize(
        companyCode: String,
        verboseLogging: Bool = false, // When set to true, the SDK will print verbose logs to the console to help with debugging. This should be set to false in production.
        insertLinksEnabled: Bool = false, // When set to true, the SDK will activate deep links and universal links. If you are using an external provider for deep links, set this to false.
        insertLinksClipboardEnabled: Bool = false, // When set to true, the SDK use the clipboard to improve the effectiveness of deep links. This will trigger a prompt for the user to allow the app to paste from the clipboard upon init of our SDK.
        affiliateAttributionActiveTime: TimeInterval? = nil // Optional time interval (in seconds) for how long attribution remains active after affiliate link click
    ) throws {
        guard !isInitialized else {
            throw NSError(domain: "InsertAffiliateSwift", code: 1, userInfo: [NSLocalizedDescriptionKey: "SDK is already initialized."])
        }

        self.companyCode = companyCode
        self.verboseLogging = verboseLogging
        self.insertLinksEnabled = insertLinksEnabled
        self.insertLinksClipboardEnabled = insertLinksClipboardEnabled
        self.affiliateAttributionActiveTime = affiliateAttributionActiveTime
        isInitialized = true
    }

    func getCompanyCode() -> String? {
        return companyCode
    }
    
    func getVerboseLogging() -> Bool {
        return verboseLogging
    }
    
    func getInsertLinksEnabled() -> Bool {
        return insertLinksEnabled
    }
    
    func getInsertLinksClipboardEnabled() -> Bool {
        return insertLinksClipboardEnabled
    }
    
    func getAffiliateAttributionActiveTime() -> TimeInterval? {
        return affiliateAttributionActiveTime
    }

    func reset() {
        companyCode = nil
        isInitialized = false
        verboseLogging = false
        insertLinksEnabled = false
        insertLinksClipboardEnabled = false
        affiliateAttributionActiveTime = nil
        print("[Insert Affiliate] SDK has been reset.")
    }
}

public struct InsertAffiliateSwift {
    public typealias InsertAffiliateIdentifierChangeCallback = (String?) -> Void
    private static let callbackQueue = DispatchQueue(label: "com.insertaffiliate.callback", attributes: .concurrent)
    nonisolated(unsafe) private static var _insertAffiliateIdentifierChangeCallback: InsertAffiliateIdentifierChangeCallback?
    
    private static var insertAffiliateIdentifierChangeCallback: InsertAffiliateIdentifierChangeCallback? {
        get {
            callbackQueue.sync { _insertAffiliateIdentifierChangeCallback }
        }
        set {
            callbackQueue.async(flags: .barrier) { _insertAffiliateIdentifierChangeCallback = newValue }
        }
    }
    
    public static func setInsertAffiliateIdentifierChangeCallback(_ callback: @escaping InsertAffiliateIdentifierChangeCallback) {
        insertAffiliateIdentifierChangeCallback = callback
    }

    @available(iOS 13.0.0, *)
    private static let state = InsertAffiliateState()
    
    // Thread-safe storage for settings using UserDefaults
    private static let insertLinksEnabledKey = "InsertLinks_InsertLinksEnabled"
    private static let insertLinksClipboardEnabledKey = "InsertLinks_InsertLinksClipboardEnabled"
    private static let affiliateAttributionActiveTimeKey = "InsertAffiliate_AttributionActiveTime"
    
    private static var insertLinksEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: insertLinksEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: insertLinksEnabledKey) }
    }
    
    private static var insertLinksClipboardEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: insertLinksClipboardEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: insertLinksClipboardEnabledKey) }
    }
    
    private static var affiliateAttributionActiveTime: TimeInterval? {
        get { 
            let value = UserDefaults.standard.object(forKey: affiliateAttributionActiveTimeKey) as? TimeInterval
            return value
        }
        set { 
            if let timeout = newValue {
                UserDefaults.standard.set(timeout, forKey: affiliateAttributionActiveTimeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: affiliateAttributionActiveTimeKey)
            }
        }
    }

    public static func initialize(
        companyCode: String, 
        verboseLogging: Bool = false,
        insertLinksEnabled: Bool = false,
        insertLinksClipboardEnabled: Bool = false,
        affiliateAttributionActiveTime: TimeInterval? = nil
    ) {
        guard #available(iOS 13.0, *) else {
            print("[Insert Affiliate] This SDK requires iOS 13.0 or newer.")
            return
        }

        // Store settings for immediate synchronous access
        self.insertLinksEnabled = insertLinksEnabled
        self.insertLinksClipboardEnabled = insertLinksClipboardEnabled
        self.affiliateAttributionActiveTime = affiliateAttributionActiveTime
        
        Task {
            do {
                try await state.initialize(
                    companyCode: companyCode, 
                    verboseLogging: verboseLogging,
                    insertLinksEnabled: insertLinksEnabled,
                    insertLinksClipboardEnabled: insertLinksClipboardEnabled,
                    affiliateAttributionActiveTime: affiliateAttributionActiveTime
                )
                let _ = getOrCreateUserAccountToken()
                
                // Collect system info on initialization
                if insertLinksEnabled {
                    let systemInfo = await getEnhancedSystemInfo()
                    await sendSystemInfoToBackend(systemInfo)    
                }
                
            } catch {
                print("[Insert Affiliate] Error initializing SDK: \(error.localizedDescription)")
            }
        }
    }

    public static func overrideUserAccountToken(uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: "appAccountToken")
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
    public static func returnUserAccountTokenAndStoreExpectedTransaction(overrideUUID: String? = nil) async -> UUID? {
        // 1: Check if they have a valid affiliate assigned before storing the transaction
        guard returnInsertAffiliateIdentifier() != nil else {
            print("[Insert Affiliate] No valid affiliate stored or attribution expired - not saving expected transaction")
            return nil
        }

        if let overrideUUIDString = overrideUUID {
            if let overrideUUID = UUID(uuidString: overrideUUIDString) {
                print("[Insert Affiliate] Overriding user account token with: \(overrideUUIDString)")
                await storeExpectedAppStoreTransaction(userAccountToken: overrideUUID)
                UserDefaults.standard.set(overrideUUIDString, forKey: "appAccountToken")
                return overrideUUID;
            } else {
                print("[Insert Affiliate] Invalid UUID string passed to overrideUUID: \(overrideUUIDString)")
                return nil
            }
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

    /// Validates and sets a short code for affiliate tracking
    /// - Parameter shortCode: The short code to validate and set
    /// - Returns: true if the short code exists and was successfully validated and stored, false otherwise
    public static func setShortCode(shortCode: String) async -> Bool {
        let capitalisedShortCode = shortCode.uppercased()

        guard capitalisedShortCode.count >= 3 && capitalisedShortCode.count <= 25 else {
            print("[Insert Affiliate] Error: Short code must be between 3 and 25 characters long.")
            return false
        }

        // Check if the short code contains only letters and numbers
        let alphanumericSet = CharacterSet.alphanumerics
        let isValidShortCode = capitalisedShortCode.unicodeScalars.allSatisfy { alphanumericSet.contains($0) }
        guard isValidShortCode else {
            print("[Insert Affiliate] Error: Short code must contain only letters and numbers.")
            return false
        }

        // Validate that the short code exists in the system
        guard let affiliateDetails = await getAffiliateDetails(affiliateCode: capitalisedShortCode) else {
            print("[Insert Affiliate] Error: Short code '\(capitalisedShortCode)' does not exist or validation failed.")
            return false
        }

        print("[Insert Affiliate] Short code validated successfully for affiliate: \(affiliateDetails.affiliateName)")

        // If validation passes, set the Insert Affiliate Identifier
        storeInsertAffiliateIdentifier(referringLink: capitalisedShortCode)

        // Verify it was stored successfully
        if let insertAffiliateIdentifier = returnInsertAffiliateIdentifier() {
            print("[Insert Affiliate] Successfully set affiliate identifier: \(insertAffiliateIdentifier)")
            return true
        } else {
            print("[Insert Affiliate] Failed to set affiliate identifier.")
            return false
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
        
        // Check if this is the same affiliate identifier that's already stored
        let existingIdentifier = UserDefaults.standard.string(forKey: "insertAffiliateIdentifier")
        
        if existingIdentifier == insertAffiliateIdentifier {
            // Same affiliate identifier, don't update the stored date
            Task {
                let verboseLogging = await state.getVerboseLogging()
                if verboseLogging {
                    print("[Insert Affiliate] Same affiliate identifier already stored, not updating date: \(insertAffiliateIdentifier)")
                }
            }
            return
        }
        
        // Different affiliate identifier, store it and update the date
        UserDefaults.standard.set(insertAffiliateIdentifier, forKey: "insertAffiliateIdentifier")
        
        // Store the date when the affiliate identifier was stored (AffiliateStoredDate)
        let dateFormatter = ISO8601DateFormatter()
        let currentDate = Date()
        let storedDateString = dateFormatter.string(from: currentDate)
        UserDefaults.standard.set(storedDateString, forKey: "affiliateStoredDate")
        
        Task {
            let verboseLogging = await state.getVerboseLogging()
            if verboseLogging {
                if existingIdentifier != nil {
                    print("[Insert Affiliate] Replaced affiliate identifier: \(existingIdentifier!) -> \(insertAffiliateIdentifier)")
                } else {
                    print("[Insert Affiliate] Stored new affiliate identifier: \(insertAffiliateIdentifier)")
                }
                print("[Insert Affiliate] Stored affiliate date: \(storedDateString)")
            }
        }
        
        // Notify callback of identifier change
        insertAffiliateIdentifierChangeCallback?(insertAffiliateIdentifier)

        // Automatically fetch and store offer code ONLY if it's a short code
        if isShortCode(referringLink) {
            Task {
                await retrieveAndStoreOfferCode(affiliateLink: referringLink) { offerCode in
                    if let offerCode = offerCode {
                        print("[Insert Affiliate] Automatically retrieved and stored offer code: \(offerCode)")
                    }
                }
            }
        }
    }

    public static func returnInsertAffiliateIdentifier(ignoreTimeout: Bool = false) -> String? {
        guard let affiliateIdentifier = UserDefaults.standard.string(forKey: "insertAffiliateIdentifier") else {
            return nil
        }
        
        // If ignoreTimeout is true, return the identifier regardless of timeout
        if ignoreTimeout {
            return affiliateIdentifier
        }
        
        // Check if attribution timeout is configured
        guard let attributionTimeout = affiliateAttributionActiveTime else {
            // No timeout configured, always return identifier as valid
            return affiliateIdentifier
        }
        
        // Check if stored date exists
        guard let storedDateString = UserDefaults.standard.string(forKey: "affiliateStoredDate") else {
            // No stored date (backward compatibility), return identifier as valid
            return affiliateIdentifier
        }
        
        // Parse stored date
        let dateFormatter = ISO8601DateFormatter()
        guard let storedDate = dateFormatter.date(from: storedDateString) else {
            // Invalid date format (backward compatibility), return identifier as valid
            return affiliateIdentifier
        }
        
        // Check if attribution has expired
        let currentDate = Date()
        let timeSinceStored = currentDate.timeIntervalSince(storedDate)
        
        if timeSinceStored <= attributionTimeout {
            // Attribution is still valid
            return affiliateIdentifier
        } else {
            // Attribution has expired
            return nil
        }
    }
    
    
    
    /// Returns the date when the affiliate identifier was stored
    public static func getAffiliateStoredDate() -> Date? {
        guard let storedDateString = UserDefaults.standard.string(forKey: "affiliateStoredDate") else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: storedDateString)
    }
    
    /// Checks if the current affiliate attribution is still valid based on the timeout
    /// If no timeout is configured, always returns true if affiliate exists
    public static func isAffiliateAttributionValid() -> Bool {
        return returnInsertAffiliateIdentifier() != nil
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
    
    internal static func fetchOfferCode(affiliateLink: String, completion: @Sendable @escaping (String?) -> Void) async {
        guard let companyCode = await state.getCompanyCode(), !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Cannot fetch offer code.")
            completion(nil)
            return
        }

        guard let encodedAffiliateLink = affiliateLink.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("[Insert Affiliate] Failed to encode affiliate link")
            completion(nil)
            return
        }

        let platformType = "ios"
        let offerCodeUrlString = "https://api.insertaffiliate.com/v1/affiliateReturnOfferCode/\(companyCode)/\(encodedAffiliateLink)?platformType=\(platformType)"

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

    private static func retrieveAndStoreOfferCode(affiliateLink: String, completion: @escaping @Sendable (String?) -> Void = { _ in }) async {
        await fetchOfferCode(affiliateLink: affiliateLink) { offerCode in
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
            print("[Insert Affiliate] No valid affiliate identifier found or attribution expired. Please set one before tracking events.")
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
                print("[Insert Affiliate] No response received for track event")
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
            print("[Insert Affiliate] No valid affiliate identifier found or attribution expired. Please set one before tracking events.")
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

    // MARK: - Deep Link Monitoring
    
    /// Handle all InsertAffiliate URLs (deep links, universal links, etc.)
    /// Call this method from your AppDelegate's URL handling methods
    /// Returns true if the URL was handled by InsertAffiliate, false otherwise
    @discardableResult
    public static func handleInsertLinks(_ url: URL) -> Bool {
        print("[Insert Affiliate] Attempting to handle URL: \(url.absoluteString)")
        
        // Check if deep links are enabled synchronously
        guard insertLinksEnabled else {
            print("[Insert Affiliate] Deep links are disabled, not handling URL")
            return false
        }
        
        // Handle custom URL schemes (ia-companycode://shortcode)
        if let scheme = url.scheme, scheme.starts(with: "ia-") {
            return handleCustomURLScheme(url)
        }
        
        // Handle universal links (https://insertaffiliate.link/V1/companycode/shortcode)
        if url.scheme == "https" && url.host?.contains("insertaffiliate.link") == true {
            return handleUniversalLink(url)
        }
        
        return false
    }
    
    /// Handle custom URL schemes like ia-companycode://shortcode
    private static func handleCustomURLScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme, scheme.starts(with: "ia-") else {
            return false
        }
        // Extract company code from scheme (remove "ia-" prefix)
        let companyCode = String(scheme.dropFirst(3))
        
        guard let shortCode = parseShortCodeFromURL(url) else {
            print("[Insert Affiliate] Failed to parse short code from deep link: \(url.absoluteString)")
            return false
        }
        
        print("[Insert Affiliate] Custom URL scheme detected - Company: \(companyCode), Short code: \(shortCode)")
        
        // Validate company code matches initialized one
        Task {
            if let initializedCompanyCode = await state.getCompanyCode() {
                if companyCode.lowercased() != initializedCompanyCode.lowercased() {
                    print("[Insert Affiliate] Warning: URL company code (\(companyCode)) doesn't match initialized company code (\(initializedCompanyCode))")
                }
            }
        }

        // if URL scheme is used, we can straight away store the short code as the referring link
        storeInsertAffiliateIdentifier(referringLink: shortCode)

        return true
    }
    
    /// Handle universal links like https://insertaffiliate.link/V1/companycode/shortcode
    private static func handleUniversalLink(_ url: URL) -> Bool {
        let pathComponents = url.pathComponents
        
        // Expected format: /V1/companycode/shortcode
        guard pathComponents.count >= 4,
              pathComponents[1] == "V1" else {
            print("[Insert Affiliate] Invalid universal link format: \(url.absoluteString)")
            return false
        }
        
        let companyCode = pathComponents[2]
        let shortCode = pathComponents[3]
        
        print("[Insert Affiliate] Universal link detected - Company: \(companyCode), Short code: \(shortCode)")
        
        // Validate company code matches initialized one
        Task {
            if let initializedCompanyCode = await state.getCompanyCode() {
                if companyCode.lowercased() != initializedCompanyCode.lowercased() {
                    print("[Insert Affiliate] Warning: URL company code (\(companyCode)) doesn't match initialized company code (\(initializedCompanyCode))")
                }
            }
        }
        
        // Process the affiliate attribution
        processAffiliateAttribution(shortCode: shortCode, companyCode: companyCode)
        
        return true
    }
    
    /// Process affiliate attribution with the extracted data
    private static func processAffiliateAttribution(shortCode: String, companyCode: String) {
        print("[Insert Affiliate] Processing attribution for short code: '\(shortCode)' (length: \(shortCode.count))")
        
        // Ensure the short code is uppercase
        let uppercasedShortCode = shortCode.uppercased()

        // Fetch additional affiliate data
        fetchDeepLinkData(shortCode: uppercasedShortCode, companyCode: companyCode)
    }
    
    /// Parse short code from deep link URL
    private static func parseShortCodeFromURL(_ url: URL) -> String? {
        // Handle format: ia-companycode://shortcode
        let rawShortCode = url.host ?? url.path.replacingOccurrences(of: "/", with: "")
        print("[Insert Affiliate] Raw short code from URL: '\(rawShortCode)'")
        
        guard !rawShortCode.isEmpty else {
            return nil
        }
        
        let uppercasedShortCode = rawShortCode.uppercased()
        print("[Insert Affiliate] Converted to uppercase: '\(uppercasedShortCode)'")
        
        if isShortCode(rawShortCode) {
            print("[Insert Affiliate] Short code validation passed, returning: '\(uppercasedShortCode)'")
            return uppercasedShortCode
        }
        
        // If not in standard format, still return it for processing
        print("[Insert Affiliate] Short code validation failed, still returning uppercase: '\(uppercasedShortCode)'")
        return uppercasedShortCode
    }

    
    /// Fetch deep link data from the API to get affiliate information
    private static func fetchDeepLinkData(shortCode: String, companyCode: String) {
        Task {
            let urlString = "https://insertaffiliate.link/V1/getDeepLinkData/\(companyCode)/\(shortCode)"
            print("[Insert Affiliate] Fetching deep link data from: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("[Insert Affiliate] Invalid deep link data URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("[Insert Affiliate] Error fetching deep link data: \(error.localizedDescription)")
                    return
                }
                
                // Log HTTP response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("[Insert Affiliate] Deep link API response status: \(httpResponse.statusCode)")
                    print("[Insert Affiliate] Deep link API response headers: \(httpResponse.allHeaderFields)")
                    
                    // Handle non-success status codes
                    if httpResponse.statusCode != 200 {
                        if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                            print("[Insert Affiliate] API Error (\(httpResponse.statusCode)): \(errorResponse)")
                        }
                        
                        switch httpResponse.statusCode {
                        case 404:
                            print("[Insert Affiliate] Deep link not found. The short code '\(shortCode)' may not exist for company '\(companyCode)'. Please check your Insert Affiliate dashboard.")
                        case 401, 403:
                            print("[Insert Affiliate] Authentication error. Please verify your company code.")
                        default:
                            print("[Insert Affiliate] Server error. Please try again later.")
                        }
                        return
                    }
                }
                
                guard let data = data else {
                    print("[Insert Affiliate] No data received from deep link API")
                    return
                }
                
                // Log raw response data for debugging
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("[Insert Affiliate] Raw deep link API response: \(rawResponse)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // Check for error response
                        if let errorMessage = json["error"] as? String {
                            print("[Insert Affiliate] API returned error: \(errorMessage)")
                            print("[Insert Affiliate] The short code '\(shortCode)' was not found. Please ensure it exists in your Insert Affiliate dashboard.")
                            return
                        }
                        
                        print("[Insert Affiliate] Deep link data retrieved successfully: \(json)")
                        
                        // Extract from nested structure: data.deepLink.userCode
                        if let data = json["data"] as? [String: Any],
                           let deepLink = data["deepLink"] as? [String: Any],
                           let userCode = deepLink["userCode"] as? String {
                            print("[Insert Affiliate] User code extracted: \(userCode)")
                            storeInsertAffiliateIdentifier(referringLink: userCode)
                            
                            // Store the complete response for reference
                            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) {
                                UserDefaults.standard.set(jsonData, forKey: "deepLinkData")
                            }
                            
                            // Extract values before dispatching to main queue to avoid data races
                            let affiliateEmail = deepLink["affiliateEmail"] as? String
                            let companyName = (data["company"] as? [String: Any])?["companyName"] as? String
                            
                        } else {
                            print("[Insert Affiliate] Could not extract userCode from response")
                            print("[Insert Affiliate] Available keys in response: \(json.keys)")
                            if let data = json["data"] as? [String: Any] {
                                print("[Insert Affiliate] Available keys in data: \(data.keys)")
                                if let deepLink = data["deepLink"] as? [String: Any] {
                                    print("[Insert Affiliate] DeepLink data: \(deepLink)")
                                }
                            }
                        }
                    } else {
                        print("[Insert Affiliate] Response is not a valid JSON object")
                    }
                } catch {
                    print("[Insert Affiliate] Failed to parse deep link data: \(error.localizedDescription)")
                    print("[Insert Affiliate] Data length: \(data.count) bytes")
                }
            }
            
            task.resume()
        }
    }
    
    /// Fetch deep link data using the initialized company code (fallback method)
    private static func fetchDeepLinkData(shortCode: String) {
        Task {
            guard let companyCode = await state.getCompanyCode(), !companyCode.isEmpty else {
                print("[Insert Affiliate] Company code is not set. Cannot fetch deep link data.")
                return
            }
            
            fetchDeepLinkData(shortCode: shortCode, companyCode: companyCode)
        }
    }
    
    // MARK: - Getter Methods
    
    /// Get stored affiliate email from deep link data
    public static func getAffiliateEmail() -> String? {
        return UserDefaults.standard.string(forKey: "affiliateEmail")
    }
    
    /// Get stored affiliate ID from deep link data
    public static func getAffiliateId() -> String? {
        return UserDefaults.standard.string(forKey: "affiliateId")
    }
    
    /// Get stored company name from deep link data
    public static func getCompanyName() -> String? {
        return UserDefaults.standard.string(forKey: "companyName")
    }
    
    /// Get the complete deep link data as a dictionary
    public static func getDeepLinkData() -> [String: Any]? {
        guard let data = UserDefaults.standard.data(forKey: "deepLinkData") else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("[Insert Affiliate] Failed to parse stored deep link data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Affiliate details returned from the API
    public struct AffiliateDetails {
        public let affiliateName: String
        public let affiliateShortCode: String
        public let deeplinkUrl: String
    }

    /// Retrieves detailed information about an affiliate by their short code or deep link
    /// This method queries the API and does not store or set the affiliate identifier
    /// - Parameter affiliateCode: The short code or deep link to look up
    /// - Returns: AffiliateDetails if found, nil otherwise
    public static func getAffiliateDetails(affiliateCode: String) async -> AffiliateDetails? {
        guard let companyCode = await state.getCompanyCode(), !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return nil
        }

        // Strip UUID from code if present (e.g., "ABC123-uuid" becomes "ABC123")
        let cleanCode = affiliateCode.components(separatedBy: "-").first ?? affiliateCode

        let urlString = "https://api.insertaffiliate.com/V1/checkAffiliateExists"

        guard let url = URL(string: urlString) else {
            print("[Insert Affiliate] Invalid URL for getting affiliate details")
            return nil
        }

        let payload: [String: Any] = [
            "companyId": companyCode,
            "affiliateCode": cleanCode
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("[Insert Affiliate] Failed to encode affiliate details payload")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Insert Affiliate] No response received for affiliate details")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("[Insert Affiliate] API Error (\(httpResponse.statusCode)): \(errorResponse)")
                }
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let exists = json["exists"] as? Bool,
                  exists == true,
                  let affiliate = json["affiliate"] as? [String: Any],
                  let affiliateName = affiliate["affiliateName"] as? String,
                  let affiliateShortCode = affiliate["affiliateShortCode"] as? String,
                  let deeplinkUrl = affiliate["deeplinkurl"] as? String else {
                print("[Insert Affiliate] Failed to parse affiliate details from response")
                return nil
            }

            return AffiliateDetails(
                affiliateName: affiliateName,
                affiliateShortCode: affiliateShortCode,
                deeplinkUrl: deeplinkUrl
            )

        } catch {
            print("[Insert Affiliate] Error fetching affiliate details: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Deep Linking Utilities
    
    /// Retrieves and validates clipboard content for UUID format
    private static func getClipboardUUID() -> String? {
        // Check if clipboard access is enabled
        guard insertLinksClipboardEnabled else {
            return nil
        }
        
        print("[Insert Affiliate] Getting clipboard UUID")
        
        // Check if pasteboard access is available first
        guard UIPasteboard.general.hasStrings else {
            print("[Insert Affiliate] Pasteboard has no strings or access denied")
            return nil
        }
        
        guard let clipboardString = UIPasteboard.general.string else {
            print("[Insert Affiliate] No clipboard string found or access denied")
            return nil
        }
        
        let trimmedString = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isValidUUID(trimmedString) {
            print("[Insert Affiliate] Valid clipboard UUID found: \(trimmedString)")
            return trimmedString
        }
        
        print("[Insert Affiliate] Invalid clipboard UUID found: \(trimmedString)")
        return nil
    }
    
    /// Validates if a string is a properly formatted UUID (36 characters)
    private static func isValidUUID(_ string: String) -> Bool {
        return string.count == 36 && UUID(uuidString: string) != nil
    }
    
    // MARK: - System Info Collection
    
    /// Gets network connection type and interface information
    @available(iOS 12.0, *)
    internal static func getNetworkInfo() async -> [String: Any] {
        // Simple synchronous network detection
        let monitor = NWPathMonitor()
        let currentPath = monitor.currentPath
        
        var connectionType = "unknown"
        var interfaceTypes = [String]()
        
        // Determine primary connection type from current path
        if currentPath.usesInterfaceType(.wifi) {
            connectionType = "wifi"
            interfaceTypes.append("wifi")
        }
        if currentPath.usesInterfaceType(.cellular) {
            connectionType = "cellular" 
            interfaceTypes.append("cellular")
        }
        if currentPath.usesInterfaceType(.wiredEthernet) {
            connectionType = "ethernet"
            interfaceTypes.append("ethernet")
        }
        if currentPath.usesInterfaceType(.loopback) {
            interfaceTypes.append("loopback")
        }
        if currentPath.usesInterfaceType(.other) {
            interfaceTypes.append("other")
        }
        
        // Get available interfaces
        var availableInterfaces = [String]()
        for interface in currentPath.availableInterfaces {
            switch interface.type {
            case .wifi:
                availableInterfaces.append("wifi")
            case .cellular:
                availableInterfaces.append("cellular")
            case .wiredEthernet:
                availableInterfaces.append("ethernet")
            case .loopback:
                availableInterfaces.append("loopback")
            case .other:
                availableInterfaces.append("other")
            @unknown default:
                availableInterfaces.append("unknown")
            }
        }
        
        return [
            "connectionType": connectionType,
            "interfaceTypes": interfaceTypes,
            "isExpensive": currentPath.isExpensive,
            "isConstrained": currentPath.isConstrained,
            "status": currentPath.status == .satisfied ? "connected" : "disconnected",
            "availableInterfaces": availableInterfaces
        ]
    }
    
    /// Gets detailed network path information
    @available(iOS 12.0, *)
    internal static func getNetworkPathInfo() async -> [String: Any] {
        // Simple synchronous path detection
        let monitor = NWPathMonitor()
        let currentPath = monitor.currentPath
        
        // Check for IPv4/IPv6 support by examining available interfaces
        var supportsIPv4 = false
        var supportsIPv6 = false
        
        for interface in currentPath.availableInterfaces {
            if interface.type == .wifi || interface.type == .cellular || interface.type == .wiredEthernet {
                supportsIPv4 = true
                supportsIPv6 = true
            }
        }
        
        // Get local endpoint information if available
        var localEndpoints = [String]()
        for gateway in currentPath.gateways {
            if let endpoint = gateway.debugDescription.components(separatedBy: " ").first {
                localEndpoints.append(endpoint)
            }
        }
        
        // Network interface details
        var interfaceDetails = [[String: Any]]()
        for interface in currentPath.availableInterfaces {
            var interfaceInfo = [String: Any]()
            interfaceInfo["name"] = interface.name
            interfaceInfo["index"] = interface.index
            
            // Convert interface type to string manually
            let typeString: String
            switch interface.type {
            case .wifi:
                typeString = "wifi"
            case .cellular:
                typeString = "cellular"
            case .wiredEthernet:
                typeString = "wiredEthernet"
            case .loopback:
                typeString = "loopback"
            case .other:
                typeString = "other"
            @unknown default:
                typeString = "unknown"
            }
            interfaceInfo["type"] = typeString
            
            interfaceDetails.append(interfaceInfo)
        }
        
        return [
            "supportsIPv4": supportsIPv4,
            "supportsIPv6": supportsIPv6,
            "supportsDNS": currentPath.supportsDNS,
            "hasUnsatisfiedGateway": currentPath.gateways.isEmpty,
            "gatewayCount": currentPath.gateways.count,
            "gateways": localEndpoints,
            "interfaceDetails": interfaceDetails
        ]
    }
    
    /// Collects basic system information for analytics (non-identifying data only)
    internal static func getSystemInfo() async -> [String: Any] {
        let verboseLogging = await state.getVerboseLogging()
        var systemInfo = [String: Any]()
        
        let device = await UIDevice.current
        
        systemInfo["systemName"] = await device.systemName
        systemInfo["systemVersion"] = await device.systemVersion
        systemInfo["model"] = await device.model
        systemInfo["localizedModel"] = await device.localizedModel
        systemInfo["isPhysicalDevice"] = !_isSimulator()     
        systemInfo["bundleId"] = Bundle.main.bundleIdentifier ?? "null"
        
        if verboseLogging {
            print("[Insert Affiliate] system info: \(systemInfo)")
        }

        // Device type classification
        let idiom = await UIDevice.current.userInterfaceIdiom
        switch idiom {
        case .phone:
            systemInfo["deviceType"] = "mobile"
        case .pad:
            systemInfo["deviceType"] = "tablet"
        case .tv:
            systemInfo["deviceType"] = "tv"
        case .mac:
            systemInfo["deviceType"] = "desktop"
        default:
            systemInfo["deviceType"] = "unknown"
        }
        
        return systemInfo
    }
    
    /// Helper function to detect if running on simulator
    private static func _isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Enhanced system info that includes data for API requests
    internal static func getEnhancedSystemInfo() async -> [String: Any] {
        let verboseLogging = await state.getVerboseLogging()
        
        if verboseLogging {
            print("[Insert Affiliate] Collecting enhanced system information...")
        }
        
        var systemInfo = await getSystemInfo()

        if verboseLogging {
            print("[Insert Affiliate] System info: \(systemInfo)")
        }
        
        // Add timestamp
        let dateFormatter = ISO8601DateFormatter()
        systemInfo["requestTime"] = dateFormatter.string(from: Date())
        systemInfo["requestTimestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        
        // Add user agent style information
        let device = await UIDevice.current
        let systemName = await device.systemName
        let systemVersion = await device.systemVersion
        let model = await device.model
        
        systemInfo["userAgent"] = "\(model); \(systemName) \(systemVersion)"
        
        // Add screen dimensions and device pixel ratio (matching exact field names)
        let screen = await UIScreen.main
        systemInfo["screenWidth"] = Int(await screen.bounds.width)
        systemInfo["screenHeight"] = Int(await screen.bounds.height)
        systemInfo["screenAvailWidth"] = Int(await screen.bounds.width)
        systemInfo["screenAvailHeight"] = Int(await screen.bounds.height)
        systemInfo["devicePixelRatio"] = await screen.scale
        systemInfo["screenColorDepth"] = 24
        systemInfo["screenPixelDepth"] = 24
        
        // Add hardware information (matching exact field names)
        systemInfo["hardwareConcurrency"] = ProcessInfo.processInfo.processorCount
        systemInfo["maxTouchPoints"] = await device.userInterfaceIdiom == .phone ? 10 : 0
        
        // Add screen dimensions (native iOS naming)
        systemInfo["screenInnerWidth"] = Int(await screen.bounds.width)
        systemInfo["screenInnerHeight"] = Int(await screen.bounds.height)
        systemInfo["screenOuterWidth"] = Int(await screen.bounds.width)
        systemInfo["screenOuterHeight"] = Int(await screen.bounds.height)
        
        
        
        // Add clipboard UUID if available
        if let clipboardUUID = getClipboardUUID() {
            systemInfo["clipboardID"] = clipboardUUID
            if verboseLogging {
                print("[Insert Affiliate] Found valid clipboard UUID: \(clipboardUUID)")
            }
        } else if verboseLogging {
            if insertLinksClipboardEnabled {
                print("[Insert Affiliate] Clipboard UUID not available - may require NSPasteboardGeneralUseDescription in host app's Info.plist")
            } else {
                print("[Insert Affiliate] Clipboard access is disabled")
            }
        }
        
        // Add language information (matching exact field names)
        let locale = Locale.current
        systemInfo["language"] = locale.languageCode ?? "null"
        if let regionCode = locale.regionCode {
            systemInfo["country"] = regionCode
        }
        
        // Add languages array (matching exact field names)
        var languages = [String]()
        if let languageCode = locale.languageCode {
            if let regionCode = locale.regionCode {
                languages.append("\(languageCode)-\(regionCode)")
            }
            languages.append(languageCode)
        }
        systemInfo["languages"] = languages
        
        // Add timezone info (matching exact field names)
        let timeZone = TimeZone.current
        systemInfo["timezoneOffset"] = -(timeZone.secondsFromGMT() / 60)
        systemInfo["timezone"] = timeZone.identifier
        
        // Add browser and platform info (matching exact field names)
        // systemInfo["browser"] = "Safari"
        systemInfo["browserVersion"] = systemVersion
        systemInfo["platform"] = systemName
        systemInfo["os"] = systemName
        systemInfo["osVersion"] = systemVersion
        
        // Add real network connection info
        if #available(iOS 12.0, *) {
            if verboseLogging {
                print("[Insert Affiliate] Getting network info")
            }

            let networkInfo = await getNetworkInfo()
            let pathInfo = await getNetworkPathInfo()

              if verboseLogging {
                print("[Insert Affiliate] Network info: \(networkInfo)")
                print("[Insert Affiliate] Network path info: \(pathInfo)")
            }
            
            systemInfo["networkInfo"] = networkInfo
            systemInfo["networkPath"] = pathInfo
            
            // Update connection info with real data
            var connection = [String: Any]()
            connection["type"] = networkInfo["connectionType"] as? String ?? "unknown"
            connection["isExpensive"] = networkInfo["isExpensive"] as? Bool ?? false
            connection["isConstrained"] = networkInfo["isConstrained"] as? Bool ?? false
            connection["status"] = networkInfo["status"] as? String ?? "unknown"
            connection["interfaces"] = networkInfo["availableInterfaces"] as? [String] ?? []
            connection["supportsIPv4"] = pathInfo["supportsIPv4"] as? Bool ?? true
            connection["supportsIPv6"] = pathInfo["supportsIPv6"] as? Bool ?? false
            connection["supportsDNS"] = pathInfo["supportsDNS"] as? Bool ?? true
            
            // Keep legacy fields for compatibility
            connection["downlink"] = networkInfo["connectionType"] as? String == "wifi" ? 100 : 10
            connection["effectiveType"] = networkInfo["connectionType"] as? String == "wifi" ? "4g" : "3g"
            connection["rtt"] = networkInfo["connectionType"] as? String == "wifi" ? 20 : 100
            connection["saveData"] = networkInfo["isConstrained"] as? Bool ?? false
            
            systemInfo["connection"] = connection

        }
        
        if verboseLogging {
            print("[Insert Affiliate] Enhanced system info collected: \(systemInfo)")
        }
        
        return systemInfo
    }
    
    /// Sends enhanced system info to the backend API for deep link event tracking
    internal static func sendSystemInfoToBackend(_ systemInfo: [String: Any]) async {
        let verboseLogging = await state.getVerboseLogging()
        
        if verboseLogging {
            print("[Insert Affiliate] Sending system info to backend...")
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: systemInfo, options: []) else {
            print("[Insert Affiliate] Failed to encode system info payload")
            return
        }
        
        let apiUrlString = "https://insertaffiliate.link/V1/appDeepLinkEvents"

        guard let apiUrl = URL(string: apiUrlString) else {
            print("[Insert Affiliate] Invalid backend API URL")
            return
        }
        
        // Create and configure the request
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        if verboseLogging {
            print("[Insert Affiliate] Sending request to: \(apiUrlString)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Insert Affiliate] No response received for system info")
                return
            }
            
            if verboseLogging {
                print("[Insert Affiliate] System info response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[Insert Affiliate] System info response: \(responseString)")
                }
            }

            // Try to parse backend response and persist matched short code if present
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let json = jsonObject as? [String: Any] {
                let matchFound = json["matchFound"] as? Bool ?? false
                if matchFound, let matchedShortCode = json["matched_affiliate_shortCode"] as? String, !matchedShortCode.isEmpty {
                    if verboseLogging {
                        print("[Insert Affiliate] Matched short code from backend: \(matchedShortCode)")
                    }
                    
                    
                    if verboseLogging {
                        print("[Insert Affiliate] Insert Affiliate Identifier before updating from backend (matched short code): \(returnInsertAffiliateIdentifier() ?? "nil")")
                    }

                    storeInsertAffiliateIdentifier(referringLink: matchedShortCode)

                    
                    if verboseLogging {
                        print("[Insert Affiliate] Updated Insert Affiliate Identifier after updating from backend (matched short code): \(returnInsertAffiliateIdentifier() ?? "nil")")
                    }
                }
            }
            
            // Check for a successful response
            if (200...299).contains(httpResponse.statusCode) {
                if verboseLogging {
                    print("[Insert Affiliate] System info sent successfully")
                }
            } else {
                print("[Insert Affiliate] Failed to send system info with status code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[Insert Affiliate] Error response: \(responseString)")
                }
            }
        } catch {
            print("[Insert Affiliate] Error sending system info: \(error.localizedDescription)")
        }
    }
    
}

