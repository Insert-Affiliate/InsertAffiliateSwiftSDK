import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif

// In-app referrals: turn the app's own user into an affiliate, read their
// referral stats and share their link. Backend: /V1/sdk/affiliate.
//
// The company ID is public (it ships in every app binary), so reading the
// user's own stats needs the device token issued on enrol/verify. The token is
// stored per company ID in the Keychain and is never logged.

extension InsertAffiliateSwift {

    // MARK: - In-App Referrals: Types

    /// What happened when enrolling (or reconnecting) the app's user as an affiliate.
    public enum ReferralEnrolmentStatus: String, Sendable {
        /// A new affiliate was created and this device is connected.
        case created
        /// The user was already an affiliate; this device is now connected.
        case connected
        /// The user is already an affiliate. A 6-digit code was emailed to them;
        /// pass it to `verifyAffiliateCode(email:code:name:)`.
        case verificationRequired
        /// See `errorCode` and `errorMessage`.
        case error
    }

    /// Result of `createAffiliateForUser(email:name:options:)` and `verifyAffiliateCode(email:code:name:options:)`.
    public struct ReferralEnrolmentResult: Sendable, Equatable {
        public let status: ReferralEnrolmentStatus
        /// The user's affiliate, present when status is `.created` or `.connected`.
        public let affiliate: AffiliateDetails?
        /// Server codes (`INVALID_EMAIL`, `INVALID_CODE`, `PROGRAM_DISABLED`,
        /// `AFFILIATE_LIMIT_REACHED`, `COMPANY_NOT_FOUND`, `TOO_MANY_CODES`,
        /// `RATE_LIMITED`, ...) plus `NETWORK_ERROR` and `NOT_INITIALIZED` from the SDK.
        public let errorCode: String?
        public let errorMessage: String?
    }

    /// The signed-in referrer's affiliate details and referral stats, from `getMyAffiliateDetails()`.
    /// Values read on the device are for display. Grant anything valuable from your server
    /// (the `referral.created` webhook or the Public API).
    public struct MyAffiliateDetails: Sendable, Equatable, Decodable {
        public let affiliateName: String
        public let affiliateShortCode: String
        public let deeplinkUrl: String
        /// What counts as a referral for this app: `install`, `event` or `purchase`.
        public let referralTrigger: String
        /// The count for `referralTrigger`. Only goes up, so compare it with what you have already rewarded.
        public let referralCount: Int
        public let installCount: Int
        public let eventCount: Int
        public let purchaseCount: Int
        public let totalEarned: Double
        public let totalPaid: Double
        public let totalUnpaid: Double
        public let currency: String
        /// Where the referrer signs in to their full affiliate dashboard.
        public let dashboardUrl: String
        /// How many rewards the referrer has been given for their referrals.
        public let rewardsGranted: Int
        /// When the referrer's free premium from rewards ends, or nil when they have none.
        public let premiumUntil: Date?
        /// App Store one-time offer codes given as rewards, newest first.
        public let rewardCodes: [ReferralRewardCode]

        /// The code and link part of these details.
        public var affiliate: AffiliateDetails {
            AffiliateDetails(affiliateName: affiliateName, affiliateShortCode: affiliateShortCode, deeplinkUrl: deeplinkUrl)
        }

        enum CodingKeys: String, CodingKey {
            case affiliateName, affiliateShortCode, referralTrigger, referralCount, installCount, eventCount,
                 purchaseCount, totalEarned, totalPaid, totalUnpaid, currency, dashboardUrl,
                 rewardsGranted, premiumUntil, rewardCodes
            case deeplinkUrl = "deeplinkurl"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            affiliateName = c.lenientString(.affiliateName)
            affiliateShortCode = c.lenientString(.affiliateShortCode)
            deeplinkUrl = c.lenientString(.deeplinkUrl)
            referralTrigger = referralTriggerValue(c.lenientString(.referralTrigger))
            referralCount = Int(c.lenientDouble(.referralCount))
            installCount = Int(c.lenientDouble(.installCount))
            eventCount = Int(c.lenientDouble(.eventCount))
            purchaseCount = Int(c.lenientDouble(.purchaseCount))
            totalEarned = c.lenientDouble(.totalEarned)
            totalPaid = c.lenientDouble(.totalPaid)
            totalUnpaid = c.lenientDouble(.totalUnpaid)
            let currencyValue = c.lenientString(.currency)
            currency = currencyValue.isEmpty ? "USD" : currencyValue
            dashboardUrl = c.lenientString(.dashboardUrl)
            rewardsGranted = Int(c.lenientDouble(.rewardsGranted))
            premiumUntil = referralDate(c.lenientString(.premiumUntil))
            // Codes that can't be read (no code or no valid link) are left out.
            let codes = (try? c.decodeIfPresent([LenientElement<ReferralRewardCode>].self, forKey: .rewardCodes)) ?? nil
            rewardCodes = codes?.compactMap { $0.value } ?? []
        }
    }

    /// A reward code given to the referrer: an App Store one-time offer code,
    /// or a Google Play promo code if they were rewarded on an Android phone.
    public struct ReferralRewardCode: Sendable, Equatable, Decodable {
        public static let appStore = "app_store"
        public static let googlePlay = "google_play"

        public let code: String
        /// Opens the store to redeem the code.
        public let redeemUrl: URL
        /// Which store the code is for: `appStore` or `googlePlay`. Older servers
        /// don't send it; those codes are App Store codes.
        public let store: String
        public let grantedAt: Date?

        /// Whether the code can be redeemed on this iPhone.
        public var isAppStore: Bool { store == Self.appStore }

        enum CodingKeys: String, CodingKey {
            case code, redeemUrl, store, grantedAt
        }

        public init(code: String, redeemUrl: URL, store: String = ReferralRewardCode.appStore, grantedAt: Date? = nil) {
            self.code = code
            self.redeemUrl = redeemUrl
            self.store = store
            self.grantedAt = grantedAt
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let codeValue = c.lenientString(.code)
            guard !codeValue.isEmpty, let url = URL(string: c.lenientString(.redeemUrl)), url.scheme != nil else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Reward code without a code or redeem link"))
            }
            code = codeValue
            redeemUrl = url
            let storeValue = c.lenientString(.store)
            store = storeValue.isEmpty ? Self.appStore : storeValue
            grantedAt = referralDate(c.lenientString(.grantedAt))
        }
    }

    /// The referrer's own accounts, so the server can give them rewards and stop
    /// them counting as their own referral. Leave out what your app doesn't use.
    public struct ReferrerAccountOptions: Sendable, Equatable {
        /// The user's RevenueCat app user id or Adapty customer user id.
        public var appUserId: String?
        /// The user's own Google Play subscription purchase token (Android only).
        public var playPurchaseToken: String?

        public init(appUserId: String? = nil, playPurchaseToken: String? = nil) {
            self.appUserId = appUserId
            self.playPurchaseToken = playPurchaseToken
        }
    }

    /// The company's in-app referral settings from the portal, from `getReferralProgramConfig()`.
    public struct ReferralProgramConfig: Sendable, Equatable, Decodable {
        public let enabled: Bool
        public let companyName: String
        public let referralTrigger: String
        /// Drop-in screen copy set in the portal. Empty when not set.
        public let headline: String
        public let rewardText: String
        /// `#RRGGBB`, or empty when not set.
        public let primaryColor: String

        enum CodingKeys: String, CodingKey {
            case enabled, companyName, referralTrigger, headline, rewardText, primaryColor
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            enabled = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) == true
            companyName = c.lenientString(.companyName)
            referralTrigger = referralTriggerValue(c.lenientString(.referralTrigger))
            headline = c.lenientString(.headline)
            rewardText = c.lenientString(.rewardText)
            primaryColor = c.lenientString(.primaryColor)
        }
    }

    // MARK: - In-App Referrals: Public Methods

    /// Makes the app's signed-in user an affiliate of this app (a "referrer").
    ///
    /// - New email: creates the affiliate, stores this device's token and returns `.created`.
    /// - Existing affiliate (reinstall, new phone): emails a 6-digit code and returns
    ///   `.verificationRequired`. Collect the code and call `verifyAffiliateCode(email:code:name:)`.
    /// - Parameter options: the user's RevenueCat / Adapty user id, so rewards can be given automatically.
    public static func createAffiliateForUser(
        email: String,
        name: String = "",
        options: ReferrerAccountOptions = ReferrerAccountOptions()
    ) async -> ReferralEnrolmentResult {
        return await postReferralEnrolment(path: "enrol", body: [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "name": name,
        ], options: options)
    }

    /// Finishes connecting an existing affiliate with the 6-digit code emailed by
    /// `createAffiliateForUser(email:name:)`. On success stores this device's token.
    public static func verifyAffiliateCode(
        email: String,
        code: String,
        name: String = "",
        options: ReferrerAccountOptions = ReferrerAccountOptions()
    ) async -> ReferralEnrolmentResult {
        return await postReferralEnrolment(path: "verify", body: [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "code": code.filter { !$0.isWhitespace },
            "name": name,
        ], options: options)
    }

    /// Saves the referrer's accounts for a user who subscribes or signs in after joining.
    /// The server then gives them any rewards that were waiting.
    /// - Returns: false when this device is not connected or the request fails. If the
    ///   server no longer accepts the stored token, it is cleared.
    @discardableResult
    public static func setReferrerAccount(appUserId: String? = nil, playPurchaseToken: String? = nil) async -> Bool {
        let verboseLogging = await state.getVerboseLogging()
        guard let stored = storedReferrerToken(verboseLogging: verboseLogging),
              let url = URL(string: "\(referralsApiBase)/me/identity") else {
            return false
        }

        let deviceId = returnShortUniqueDeviceID()
        let body = buildReferrerIdentityBody(
            options: ReferrerAccountOptions(appUserId: appUserId, playPurchaseToken: playPurchaseToken),
            deviceId: deviceId
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(stored.token, forHTTPHeaderField: "X-Insert-Affiliate-Token")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if clearReferrerTokenIfRejected(statusCode: statusCode, data: data, stored: stored, verboseLogging: verboseLogging) {
                return false
            }
            guard (200..<300).contains(statusCode) else {
                print("[Insert Affiliate] Saving referrer account failed with status: \(statusCode)")
                return false
            }
            ReferrerTokenStore.markDeviceRegistered(deviceId, companyId: stored.companyCode)
            if verboseLogging {
                print("[Insert Affiliate] Referrer account saved")
            }
            return true
        } catch {
            print("[Insert Affiliate] Error saving referrer account: \(error.localizedDescription)")
            return false
        }
    }

    /// The referrer's affiliate details and referral stats. Returns nil when this device
    /// is not connected, or when the details could not be loaded. If the server no longer
    /// accepts the stored token, it is cleared.
    public static func getMyAffiliateDetails() async -> MyAffiliateDetails? {
        let verboseLogging = await state.getVerboseLogging()
        guard let stored = storedReferrerToken(verboseLogging: verboseLogging),
              let url = URL(string: "\(referralsApiBase)/me") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(stored.token, forHTTPHeaderField: "X-Insert-Affiliate-Token")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if clearReferrerTokenIfRejected(statusCode: statusCode, data: data, stored: stored, verboseLogging: verboseLogging) {
                return nil
            }
            guard statusCode == 200 else {
                print("[Insert Affiliate] Referrer details request failed with status: \(statusCode)")
                return nil
            }
            let details = try JSONDecoder().decode(MyAffiliateDetails.self, from: data)
            registerReferrerDeviceIfNeeded(companyCode: stored.companyCode)
            return details
        } catch {
            print("[Insert Affiliate] Error getting referrer details: \(error.localizedDescription)")
            return nil
        }
    }

    /// True when this device holds a referrer token for this app. Local only, no network.
    public static func isUserAnAffiliate() -> Bool {
        guard let companyCode = syncCompanyCode, !companyCode.isEmpty else {
            return false
        }
        return ReferrerTokenStore.read(companyId: companyCode) != nil
    }

    /// Disconnects this device from the referrer's affiliate account (call on app logout).
    /// The affiliate, their earnings and dashboard are untouched.
    public static func signOutAffiliate() {
        guard let companyCode = syncCompanyCode, !companyCode.isEmpty else {
            return
        }
        ReferrerTokenStore.clear(companyId: companyCode)
        print("[Insert Affiliate] Referrer signed out on this device")
    }

    /// The company's in-app referral settings (on/off, trigger, drop-in screen copy and colour).
    /// Returns nil when the SDK is not initialized or the request fails.
    public static func getReferralProgramConfig() async -> ReferralProgramConfig? {
        guard let companyCode = syncCompanyCode, !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return nil
        }
        let encodedCompany = companyCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? companyCode
        guard let url = URL(string: "\(referralsApiBase)/config/\(encodedCompany)") else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard statusCode == 200 else {
                print("[Insert Affiliate] Referral program config request failed with status: \(statusCode)")
                return nil
            }
            return try JSONDecoder().decode(ReferralProgramConfig.self, from: data)
        } catch {
            print("[Insert Affiliate] Error getting referral program config: \(error.localizedDescription)")
            return nil
        }
    }

    #if canImport(UIKit)
    /// Opens the system share sheet with the referrer's link (or their code, for apps
    /// without links). `message` may use `{link}` and `{code}` placeholders.
    /// - Parameter from: the view controller to present from; defaults to the top-most one.
    /// - Returns: false when this device is not connected or the details could not be loaded.
    @discardableResult
    public static func shareReferralLink(message: String? = nil, from viewController: UIViewController? = nil) async -> Bool {
        async let detailsRequest = getMyAffiliateDetails()
        async let configRequest = getReferralProgramConfig()
        let (details, config) = await (detailsRequest, configRequest)
        guard let details = details else {
            print("[Insert Affiliate] Cannot share referral link: no referrer details")
            return false
        }
        let text = buildReferralShareText(affiliate: details.affiliate, companyName: config?.companyName ?? "", message: message)
        return await presentReferralShareSheet(text: text, from: viewController)
    }
    #endif

    // MARK: - In-App Referrals: Internals

    static let referralsApiBase = "https://api.insertaffiliate.com/V1/sdk/affiliate"

    // Links starting with http are shared as "<message> <link>" (default message
    // "Try {companyName}:"). Short Code Only companies have no link, so the code
    // itself is shared. An app message may use {link} and {code} placeholders.
    static func buildReferralShareText(affiliate: AffiliateDetails, companyName: String, message: String?) -> String {
        let code = affiliate.affiliateShortCode
        let link = affiliate.deeplinkUrl.lowercased().hasPrefix("http") ? affiliate.deeplinkUrl : ""
        let appName = companyName.isEmpty ? "the app" : companyName
        let custom = (message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !custom.isEmpty {
            if custom.contains("{link}") || custom.contains("{code}") {
                return custom
                    .replacingOccurrences(of: "{link}", with: link.isEmpty ? code : link)
                    .replacingOccurrences(of: "{code}", with: code)
            }
            return "\(custom) \(link.isEmpty ? code : link)"
        }
        if !link.isEmpty {
            return "Try \(appName): \(link)"
        }
        return "Use my code \(code) in \(appName)"
    }

    /// The app-supplied account ids that are set, plus this device's id. The device id is
    /// the one in the insert affiliate identifier ("{shortCode}-{deviceId}"), so the server
    /// can tell when a "friend" is really the referrer.
    static func buildReferrerIdentityBody(options: ReferrerAccountOptions, deviceId: String) -> [String: String] {
        var body: [String: String] = [:]
        if !deviceId.isEmpty {
            body["deviceId"] = deviceId
        }
        if let appUserId = options.appUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !appUserId.isEmpty {
            body["appUserId"] = appUserId
        }
        if let purchaseToken = options.playPurchaseToken?.trimmingCharacters(in: .whitespacesAndNewlines), !purchaseToken.isEmpty {
            body["playPurchaseToken"] = purchaseToken
        }
        return body
    }

    /// The company code and this device's referrer token, or nil (logged) when either is missing.
    private static func storedReferrerToken(verboseLogging: Bool) -> (companyCode: String, token: String)? {
        guard let companyCode = syncCompanyCode, !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return nil
        }
        guard let token = ReferrerTokenStore.read(companyId: companyCode) else {
            if verboseLogging {
                print("[Insert Affiliate] No referrer token stored; user is not an affiliate on this device")
            }
            return nil
        }
        return (companyCode, token)
    }

    /// True when the server says the token itself is no longer valid: 401 `INVALID_TOKEN`
    /// or 404 `AFFILIATE_NOT_FOUND`. Any other 401/404 (a proxy, an older API) is a
    /// server error and the token is kept.
    static func isReferrerTokenRejected(statusCode: Int, data: Data) -> Bool {
        guard statusCode == 401 || statusCode == 404 else { return false }
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        let code = json?["code"] as? String
        return (statusCode == 401 && code == "INVALID_TOKEN") || (statusCode == 404 && code == "AFFILIATE_NOT_FOUND")
    }

    /// Clears the stored token when the server rejected it, but only if it is still the
    /// token that was sent, so a slow request with an old token can't remove a newer one.
    /// Returns true when the token was rejected.
    private static func clearReferrerTokenIfRejected(
        statusCode: Int,
        data: Data,
        stored: (companyCode: String, token: String),
        verboseLogging: Bool
    ) -> Bool {
        guard isReferrerTokenRejected(statusCode: statusCode, data: data) else { return false }
        if verboseLogging {
            print("[Insert Affiliate] Referrer token rejected (\(statusCode)); clearing it")
        }
        ReferrerTokenStore.clear(companyId: stored.companyCode, ifToken: stored.token)
        return true
    }

    /// The Keychain token survives a reinstall but the device id does not, so a connected
    /// referrer's new device id is sent once (in the background) for the self-referral check.
    private static func registerReferrerDeviceIfNeeded(companyCode: String) {
        let deviceId = returnShortUniqueDeviceID()
        guard !deviceId.isEmpty, ReferrerTokenStore.registeredDeviceId(companyId: companyCode) != deviceId else {
            return
        }
        Task {
            await setReferrerAccount()
        }
    }

    /// Turns an enrol/verify HTTP response into the public result. The token is
    /// returned separately so it is stored without ever reaching the result.
    static func parseReferralEnrolmentResponse(statusCode: Int, data: Data) -> (result: ReferralEnrolmentResult, token: String?) {
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        let isSuccess = (200..<300).contains(statusCode)

        if isSuccess, let json = json {
            let status = json["status"] as? String
            if status == "verificationRequired" {
                return (ReferralEnrolmentResult(status: .verificationRequired, affiliate: nil, errorCode: nil, errorMessage: nil), nil)
            }
            if let status = status,
               let enrolStatus = ReferralEnrolmentStatus(rawValue: status),
               enrolStatus == .created || enrolStatus == .connected,
               let token = json["token"] as? String, !token.isEmpty {
                let affiliate = json["affiliate"] as? [String: Any] ?? [:]
                let details = AffiliateDetails(
                    affiliateName: affiliate["affiliateName"] as? String ?? "",
                    affiliateShortCode: affiliate["affiliateShortCode"] as? String ?? "",
                    deeplinkUrl: affiliate["deeplinkurl"] as? String ?? ""
                )
                return (ReferralEnrolmentResult(status: enrolStatus, affiliate: details, errorCode: nil, errorMessage: nil), token)
            }
        }

        let serverCode = json?["code"] as? String ?? ""
        let serverMessage = json?["error"] as? String ?? ""
        return (ReferralEnrolmentResult(
            status: .error,
            affiliate: nil,
            errorCode: serverCode.isEmpty ? (isSuccess ? "INVALID_RESPONSE" : "HTTP_\(statusCode)") : serverCode,
            errorMessage: serverMessage.isEmpty ? "Unexpected response from the server." : serverMessage
        ), nil)
    }

    private static func postReferralEnrolment(path: String, body: [String: String], options: ReferrerAccountOptions) async -> ReferralEnrolmentResult {
        let verboseLogging = await state.getVerboseLogging()
        guard let companyCode = syncCompanyCode, !companyCode.isEmpty else {
            print("[Insert Affiliate] Company code is not set. Please initialize the SDK with a valid company code.")
            return ReferralEnrolmentResult(status: .error, affiliate: nil, errorCode: "NOT_INITIALIZED",
                                           errorMessage: "Call initialize with your company code first.")
        }
        guard let url = URL(string: "\(referralsApiBase)/\(path)") else {
            return ReferralEnrolmentResult(status: .error, affiliate: nil, errorCode: "NETWORK_ERROR",
                                           errorMessage: "Invalid API URL.")
        }

        var payload = body
        payload.merge(buildReferrerIdentityBody(options: options, deviceId: returnShortUniqueDeviceID())) { current, _ in current }
        payload["companyId"] = companyCode
        payload["platform"] = "ios"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let (result, token) = parseReferralEnrolmentResponse(statusCode: statusCode, data: data)
            if let token = token {
                if ReferrerTokenStore.save(token, companyId: companyCode) {
                    // Enrol and verify send this device's id with the request.
                    if let deviceId = payload["deviceId"] {
                        ReferrerTokenStore.markDeviceRegistered(deviceId, companyId: companyCode)
                    }
                } else {
                    print("[Insert Affiliate] Failed to store the referrer token in the Keychain")
                }
            }
            if verboseLogging {
                print("[Insert Affiliate] Referrer \(path) result: \(result.status.rawValue)\(result.errorCode.map { " (\($0))" } ?? "")")
            }
            return result
        } catch {
            print("[Insert Affiliate] Referrer \(path) failed: \(error.localizedDescription)")
            return ReferralEnrolmentResult(status: .error, affiliate: nil, errorCode: "NETWORK_ERROR",
                                           errorMessage: "Could not reach Insert Affiliate.")
        }
    }

    #if canImport(UIKit)
    @MainActor
    static func presentReferralShareSheet(text: String, from viewController: UIViewController?) -> Bool {
        guard let presenter = viewController ?? topViewController() else {
            print("[Insert Affiliate] Cannot share referral link: no view controller to present from")
            return false
        }
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        // iPad presents the share sheet as a popover, which needs an anchor.
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(activity, animated: true)
        return true
    }

    @MainActor
    static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
    #endif
}

// The server only sends these three; anything else falls back to its default.
private func referralTriggerValue(_ value: String) -> String {
    return ["install", "event", "purchase"].contains(value) ? value : "purchase"
}

// Server dates are ISO 8601, with or without fractional seconds.
func referralDate(_ text: String) -> Date? {
    guard !text.isEmpty else { return nil }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: text) {
        return date
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: text)
}

// Decodes one array element, or nil when it can't be read, so one bad item doesn't fail the list.
private struct LenientElement<Element: Decodable>: Decodable {
    let value: Element?

    init(from decoder: Decoder) {
        value = try? Element(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    // Missing or mistyped fields decode to empty/zero rather than failing the whole response.
    func lenientString(_ key: Key) -> String {
        return ((try? decodeIfPresent(String.self, forKey: key)) ?? nil) ?? ""
    }

    func lenientDouble(_ key: Key) -> Double {
        if let value = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil {
            return value.isFinite ? value : 0
        }
        if let text = (try? decodeIfPresent(String.self, forKey: key)) ?? nil, let value = Double(text) {
            return value.isFinite ? value : 0
        }
        return 0
    }
}

/// The referrer's device token, one per company ID, in the Keychain so it survives
/// delete and reinstall. Never log the token. The device id last sent to the server
/// for that token is kept in UserDefaults, so it is forgotten on reinstall.
enum ReferrerTokenStore {
    private static let service = "com.insertaffiliate.referrer"

    private static func registeredDeviceKey(companyId: String) -> String {
        return "InsertAffiliate_ReferrerDeviceId_\(companyId)"
    }

    static func registeredDeviceId(companyId: String) -> String? {
        return UserDefaults.standard.string(forKey: registeredDeviceKey(companyId: companyId))
    }

    static func markDeviceRegistered(_ deviceId: String, companyId: String) {
        UserDefaults.standard.set(deviceId, forKey: registeredDeviceKey(companyId: companyId))
    }

    static func forgetRegisteredDevice(companyId: String) {
        UserDefaults.standard.removeObject(forKey: registeredDeviceKey(companyId: companyId))
    }

    private static func baseQuery(companyId: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: companyId,
        ]
    }

    static func read(companyId: String) -> String? {
        var query = baseQuery(companyId: companyId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            return nil
        }
        return token
    }

    @discardableResult
    static func save(_ token: String, companyId: String) -> Bool {
        let data = Data(token.utf8)
        let query = baseQuery(companyId: companyId)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        forgetRegisteredDevice(companyId: companyId)
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }
        guard updateStatus == errSecItemNotFound else {
            return false
        }
        var addQuery = query
        addQuery.merge(attributes) { _, new in new }
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    static func clear(companyId: String) {
        forgetRegisteredDevice(companyId: companyId)
        SecItemDelete(baseQuery(companyId: companyId) as CFDictionary)
    }

    /// Clears the token only while it is still `token`.
    static func clear(companyId: String, ifToken token: String) {
        guard read(companyId: companyId) == token else { return }
        clear(companyId: companyId)
    }
}
