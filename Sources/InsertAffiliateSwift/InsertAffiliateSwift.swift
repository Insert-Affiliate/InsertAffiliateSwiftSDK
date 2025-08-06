import Foundation
import UIKit

@available(iOS 13.0.0, *)
actor InsertAffiliateState {
    private var companyCode: String?
    private var isInitialized = false
    private var verboseLogging = false

    func initialize(companyCode: String?, verboseLogging: Bool = false) throws {
        guard !isInitialized else {
            throw NSError(domain: "InsertAffiliateSwift", code: 1, userInfo: [NSLocalizedDescriptionKey: "SDK is already initialized."])
        }

        if let code = companyCode, !code.isEmpty {
            self.companyCode = code
            self.verboseLogging = verboseLogging
            isInitialized = true
            print("[Insert Affiliate] SDK initialized with company code: \(code), verbose logging: \(verboseLogging)")
        } else {
            self.companyCode = nil
            self.verboseLogging = verboseLogging
            isInitialized = true
            print("[Insert Affiliate] SDK initialized without a company code, verbose logging: \(verboseLogging)")
        }
    }

    func getCompanyCode() -> String? {
        return companyCode
    }
    
    func getVerboseLogging() -> Bool {
        return verboseLogging
    }

    func reset() {
        companyCode = nil
        isInitialized = false
        verboseLogging = false
        print("[Insert Affiliate] SDK has been reset.")
    }
}

public struct InsertAffiliateSwift {
    @available(iOS 13.0.0, *)
    private static let state = InsertAffiliateState()

    public static func initialize(companyCode: String?, verboseLogging: Bool = false) {
        guard #available(iOS 13.0, *) else {
            print("[Insert Affiliate] This SDK requires iOS 13.0 or newer.")
            return
        }

        Task {
            do {
                try await state.initialize(companyCode: companyCode, verboseLogging: verboseLogging)
                getOrCreateUserAccountToken()
                
                // Collect system info on initialization
                let _ = await getEnhancedSystemInfo()
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

        print("[Insert Affiliate] Tracking event '\(eventName)' with payload: \(payload)")

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("[Insert Affiliate] Failed to encode event payload")
            return
        }

        let apiUrlString = "https://api.insertaffiliate.com/v1/trackEvent"
        print("[Insert Affiliate] Sending track event to: \(apiUrlString)")

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

            // Log response details
            print("[Insert Affiliate] Track event response status: \(httpResponse.statusCode)")
            print("[Insert Affiliate] Track event response headers: \(httpResponse.allHeaderFields)")
            
            // Log response data for debugging
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("[Insert Affiliate] Track event response body: \(responseString)")
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

    // MARK: - Deep Link Monitoring
    
    /// Handle all InsertAffiliate URLs (deep links, universal links, etc.)
    /// Call this method from your AppDelegate's URL handling methods
    /// Returns true if the URL was handled by InsertAffiliate, false otherwise
    public static func handleURL(_ url: URL) -> Bool {
        print("[Insert Affiliate] Attempting to handle URL: \(url.absoluteString)")
        
        // Handle custom URL schemes (ia-companycode://shortcode)
        if let scheme = url.scheme, scheme.starts(with: "ia-") {
            return handleCustomURLScheme(url)
        }
        
        // Handle universal links (https://api.insertaffiliate.com/V1/companycode/shortcode)
        if url.scheme == "https" && url.host?.contains("insertaffiliate.com") == true {
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
        
        // Process the affiliate attribution
        processAffiliateAttribution(shortCode: shortCode, companyCode: companyCode)
        
        return true
    }
    
    /// Handle universal links like https://api.insertaffiliate.com/V1/companycode/shortcode
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
        print("[Insert Affiliate] Ensuring uppercase short code: '\(uppercasedShortCode)'")
        
        // Store the affiliate identifier
        // storeInsertAffiliateIdentifier(referringLink: uppercasedShortCode)
        
        // Fetch additional affiliate data
        fetchDeepLinkData(shortCode: uppercasedShortCode, companyCode: companyCode)
        
        // Log the attribution event
        // Task {
        //     await trackEvent(eventName: "affiliate_attribution_processed")
        // }
    }
    
    /// Handle deep links with the format `ia-companycode://shortcode`
    /// Call this method from your AppDelegate's URL handling methods
    /// @deprecated Use handleURL(_:) instead
    public static func handleDeepLink(_ url: URL) -> Bool {
        print("[Insert Affiliate] handleDeepLink is deprecated. Use handleURL(_:) instead.")
        return handleURL(url)
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
            let urlString = "https://api.insertaffiliate.com/V1/getDeepLinkData/\(companyCode)/\(shortCode)"
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
                            
                            // Show alert for TestFlight visibility only when verbose logging is enabled
                            Task { @MainActor in
                                if await InsertAffiliateSwift.state.getVerboseLogging() {
                                    InsertAffiliateSwift.showDeepLinkAlert(userCode: userCode, 
                                                                         affiliateEmail: affiliateEmail,
                                                                         companyName: companyName)
                                }
                            }
                            
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
    
    // MARK: - System Info Collection
    
    /// Collects basic system information for analytics (non-identifying data only)
    internal static func getSystemInfo() async -> [String: Any] {
        var systemInfo = [String: Any]()
        
        let device = await UIDevice.current
        
        // Basic device information (non-identifying)
        var deviceInfo = [String: Any]()
        deviceInfo["systemName"] = await device.systemName
        deviceInfo["systemVersion"] = await device.systemVersion
        deviceInfo["model"] = await device.model
        deviceInfo["localizedModel"] = await device.localizedModel
        deviceInfo["isPhysicalDevice"] = !_isSimulator()
        
        systemInfo["device_info"] = deviceInfo
        
        // Platform information
        systemInfo["platform"] = "iOS"
        systemInfo["os"] = await device.systemName
        systemInfo["osVersion"] = await device.systemVersion
        
        // Locale and language information
        systemInfo["language_code"] = Locale.current.languageCode ?? "en"
        systemInfo["time_zone"] = TimeZone.current.identifier
        
        // App information (if available)
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            systemInfo["app_version"] = appVersion
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
    
    /// Public method to get system information for analytics
    public static func getSystemInformation() async -> [String: Any] {
        return await getSystemInfo()
    }
    
    /// Enhanced system info that includes fingerprint-like data for API requests
    internal static func getEnhancedSystemInfo() async -> [String: Any] {
        let verboseLogging = await state.getVerboseLogging()
        
        if verboseLogging {
            print("[Insert Affiliate] Collecting enhanced system information...")
        }
        
        var systemInfo = await getSystemInfo()
        
        // Add timestamp
        let dateFormatter = ISO8601DateFormatter()
        systemInfo["requestTime"] = dateFormatter.string(from: Date())
        systemInfo["requestTimestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        
        // Add user agent style information
        let device = await UIDevice.current
        let systemName = await device.systemName
        let systemVersion = await device.systemVersion
        let model = await device.model
        
        systemInfo["userAgent"] = "InsertAffiliateSwift/1.0 (\(model); \(systemName) \(systemVersion))"
        
        // Add protocol and method info (for API compatibility)
        systemInfo["protocol"] = "https"
        systemInfo["method"] = "POST"
        systemInfo["secure"] = true
        
        if verboseLogging {
            print("[Insert Affiliate] Enhanced system info collected: \(systemInfo)")
        }
        
        return systemInfo
    }
    
    // MARK: - UI Feedback
    
    /// Shows an alert with deep link information for TestFlight visibility
    @MainActor private static func showDeepLinkAlert(userCode: String, affiliateEmail: String?, companyName: String?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("[Insert Affiliate] Could not find window to show alert")
            return
        }
        
        let alert = UIAlertController(
            title: "🎉 Deep Link Success",
            message: buildAlertMessage(userCode: userCode, affiliateEmail: affiliateEmail, companyName: companyName),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Find the top-most view controller to present the alert
        var topViewController = window.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        topViewController?.present(alert, animated: true)
    }
    
    /// Builds the alert message with available information
    private static func buildAlertMessage(userCode: String, affiliateEmail: String?, companyName: String?) -> String {
        var message = "InsertAffiliate deep link processed successfully!\n\n"
        message += "User Code: \(userCode)\n"
        
        if let email = affiliateEmail {
            message += "Affiliate: \(email)\n"
        }
        
        if let company = companyName {
            message += "Company: \(company)\n"
        }
        
        message += "\nAttribution has been recorded."
        return message
    }
}

