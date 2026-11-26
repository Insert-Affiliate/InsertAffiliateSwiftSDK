import XCTest
@testable import InsertAffiliateSwift

final class InsertAffiliateReferralsTests: XCTestCase {

    // MARK: - JSON decoding

    func testDecodesMyAffiliateDetails() throws {
        let json = """
        {
          "affiliateName": "Jane",
          "affiliateShortCode": "A1B2C3D4",
          "deeplinkurl": "https://insertaffiliate.link/abc",
          "referralTrigger": "event",
          "referralCount": 7,
          "installCount": 19,
          "purchaseCount": 7,
          "eventCount": 11,
          "totalEarned": 42.5,
          "totalPaid": 30,
          "totalUnpaid": 12.5,
          "currency": "USD",
          "dashboardUrl": "https://app.insertaffiliate.com/signin"
        }
        """
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8))

        XCTAssertEqual(details.affiliateName, "Jane")
        XCTAssertEqual(details.affiliateShortCode, "A1B2C3D4")
        XCTAssertEqual(details.deeplinkUrl, "https://insertaffiliate.link/abc")
        XCTAssertEqual(details.referralTrigger, "event")
        XCTAssertEqual(details.referralCount, 7)
        XCTAssertEqual(details.installCount, 19)
        XCTAssertEqual(details.purchaseCount, 7)
        XCTAssertEqual(details.eventCount, 11)
        XCTAssertEqual(details.totalEarned, 42.5)
        XCTAssertEqual(details.totalPaid, 30)
        XCTAssertEqual(details.totalUnpaid, 12.5)
        XCTAssertEqual(details.currency, "USD")
        XCTAssertEqual(details.dashboardUrl, "https://app.insertaffiliate.com/signin")
        XCTAssertEqual(details.affiliate.affiliateShortCode, "A1B2C3D4")
    }

    func testMyAffiliateDetailsToleratesMissingAndMistypedFields() throws {
        let json = """
        { "affiliateShortCode": "CODE1", "referralCount": "3", "totalEarned": null, "referralTrigger": "other" }
        """
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8))

        XCTAssertEqual(details.affiliateShortCode, "CODE1")
        XCTAssertEqual(details.affiliateName, "")
        XCTAssertEqual(details.deeplinkUrl, "")
        XCTAssertEqual(details.referralCount, 3)
        XCTAssertEqual(details.totalEarned, 0)
        XCTAssertEqual(details.referralTrigger, "purchase")
        XCTAssertEqual(details.currency, "USD")
    }

    func testDecodesRewardFields() throws {
        let json = """
        {
          "affiliateShortCode": "CODE1",
          "rewardsGranted": 3,
          "premiumUntil": "2030-01-15T10:30:00.000Z",
          "rewardCodes": [
            { "code": "OFFER2", "redeemUrl": "https://apps.apple.com/redeem?ctx=offercodes&id=1&code=OFFER2",
              "grantedAt": "2026-09-10T08:00:00.123Z" },
            { "code": "OFFER1", "redeemUrl": "https://apps.apple.com/redeem?ctx=offercodes&id=1&code=OFFER1",
              "grantedAt": "2026-09-01T08:00:00Z" }
          ]
        }
        """
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8))

        XCTAssertEqual(details.rewardsGranted, 3)
        XCTAssertEqual(details.premiumUntil, Date(timeIntervalSince1970: 1_894_703_400))
        XCTAssertEqual(details.rewardCodes.map(\.code), ["OFFER2", "OFFER1"])
        XCTAssertEqual(details.rewardCodes[0].redeemUrl.absoluteString,
                       "https://apps.apple.com/redeem?ctx=offercodes&id=1&code=OFFER2")
        XCTAssertEqual(details.rewardCodes[0].grantedAt?.timeIntervalSince1970 ?? 0, 1_789_027_200.123, accuracy: 0.001)
        XCTAssertEqual(details.rewardCodes[1].grantedAt, Date(timeIntervalSince1970: 1_788_249_600))
    }

    func testRewardCodeStore() throws {
        let json = """
        {
          "rewardCodes": [
            { "code": "PLAYCODE1", "redeemUrl": "https://play.google.com/redeem?code=PLAYCODE1", "store": "google_play" },
            { "code": "OFFER1", "redeemUrl": "https://apps.apple.com/redeem?ctx=offercodes&id=1&code=OFFER1", "store": "app_store" },
            { "code": "OLDCODE", "redeemUrl": "https://apps.apple.com/redeem?ctx=offercodes&id=1&code=OLDCODE" }
          ]
        }
        """
        let codes = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8)).rewardCodes

        XCTAssertEqual(codes.map(\.store), ["google_play", "app_store", "app_store"])
        // The referral screen on iPhone only shows codes it can redeem.
        XCTAssertEqual(codes.filter(\.isAppStore).map(\.code), ["OFFER1", "OLDCODE"])
    }

    func testRewardFieldsDefaultWhenMissingOrUnreadable() throws {
        let missing = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data("{}".utf8))
        XCTAssertEqual(missing.rewardsGranted, 0)
        XCTAssertNil(missing.premiumUntil)
        XCTAssertEqual(missing.rewardCodes, [])

        let json = """
        {
          "rewardsGranted": "2",
          "premiumUntil": null,
          "rewardCodes": [
            { "code": "GOOD", "redeemUrl": "https://apps.apple.com/redeem?code=GOOD", "grantedAt": "not a date" },
            { "code": "", "redeemUrl": "https://apps.apple.com/redeem?code=x" },
            { "code": "NOLINK" },
            "junk"
          ]
        }
        """
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8))
        XCTAssertEqual(details.rewardsGranted, 2)
        XCTAssertNil(details.premiumUntil)
        XCTAssertEqual(details.rewardCodes.map(\.code), ["GOOD"])
        XCTAssertNil(details.rewardCodes[0].grantedAt)

        let notAList = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self,
                                                from: Data(#"{ "rewardCodes": "nope", "premiumUntil": 5 }"#.utf8))
        XCTAssertEqual(notAList.rewardCodes, [])
        XCTAssertNil(notAList.premiumUntil)
    }

    func testDecodesEarnedFields() throws {
        let json = """
        { "rewardDaysEarned": 90, "earnedDisplay": { "cash": false, "days": true } }
        """
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data(json.utf8))
        XCTAssertEqual(details.rewardDaysEarned, 90)
        XCTAssertEqual(details.earnedDisplay, InsertAffiliateSwift.ReferralEarnedDisplay(cash: false, days: true))
    }

    func testEarnedFieldsFallBackForOlderServers() throws {
        let missing = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self, from: Data("{}".utf8))
        XCTAssertEqual(missing.rewardDaysEarned, 0)
        XCTAssertEqual(missing.earnedDisplay, .cashOnly)

        let junk = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self,
                                            from: Data(#"{ "rewardDaysEarned": null, "earnedDisplay": "yes" }"#.utf8))
        XCTAssertEqual(junk.rewardDaysEarned, 0)
        XCTAssertEqual(junk.earnedDisplay, .cashOnly)

        let partial = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self,
                                               from: Data(#"{ "earnedDisplay": { "days": true } }"#.utf8))
        XCTAssertEqual(partial.earnedDisplay, InsertAffiliateSwift.ReferralEarnedDisplay(cash: true, days: true))
    }

    func testDecodesReferralProgramConfig() throws {
        let json = """
        {
          "enabled": true,
          "companyName": "Velvet",
          "referralTrigger": "install",
          "headline": "Give a week, get a week",
          "rewardText": "Get a free week for every friend who subscribes.",
          "primaryColor": "#112233"
        }
        """
        let config = try JSONDecoder().decode(InsertAffiliateSwift.ReferralProgramConfig.self, from: Data(json.utf8))

        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.companyName, "Velvet")
        XCTAssertEqual(config.referralTrigger, "install")
        XCTAssertEqual(config.headline, "Give a week, get a week")
        XCTAssertEqual(config.rewardText, "Get a free week for every friend who subscribes.")
        XCTAssertEqual(config.primaryColor, "#112233")
        // Older servers don't send showCode.
        XCTAssertTrue(config.showCode)

        let hidden = try JSONDecoder().decode(InsertAffiliateSwift.ReferralProgramConfig.self,
                                              from: Data(#"{ "showCode": false }"#.utf8))
        XCTAssertFalse(hidden.showCode)
    }

    func testReferralProgramConfigDefaultsWhenFieldsMissing() throws {
        let config = try JSONDecoder().decode(InsertAffiliateSwift.ReferralProgramConfig.self, from: Data("{}".utf8))

        XCTAssertFalse(config.enabled)
        XCTAssertEqual(config.companyName, "")
        XCTAssertEqual(config.referralTrigger, "purchase")
        XCTAssertEqual(config.primaryColor, "")
    }

    // MARK: - Enrol / verify responses

    func testParsesCreatedResponseAndKeepsTokenOutOfResult() {
        let json = """
        { "status": "created", "token": "secret-token",
          "affiliate": { "affiliateName": "Jane", "affiliateShortCode": "CODE1", "deeplinkurl": "https://x.link/1" } }
        """
        let (result, token) = InsertAffiliateSwift.parseReferralEnrolmentResponse(statusCode: 200, data: Data(json.utf8))

        XCTAssertEqual(result.status, .created)
        XCTAssertEqual(token, "secret-token")
        XCTAssertEqual(result.affiliate?.affiliateShortCode, "CODE1")
        XCTAssertEqual(result.affiliate?.deeplinkUrl, "https://x.link/1")
        XCTAssertNil(result.errorCode)
    }

    func testParsesConnectedResponse() {
        let json = """
        { "status": "connected", "token": "t", "affiliate": { "affiliateName": "Jane", "affiliateShortCode": "CODE1", "deeplinkurl": "" } }
        """
        let (result, token) = InsertAffiliateSwift.parseReferralEnrolmentResponse(statusCode: 200, data: Data(json.utf8))

        XCTAssertEqual(result.status, .connected)
        XCTAssertEqual(token, "t")
    }

    func testParsesVerificationRequired() {
        let (result, token) = InsertAffiliateSwift.parseReferralEnrolmentResponse(
            statusCode: 200, data: Data(#"{ "status": "verificationRequired" }"#.utf8))

        XCTAssertEqual(result.status, .verificationRequired)
        XCTAssertNil(token)
        XCTAssertNil(result.affiliate)
    }

    func testParsesServerError() {
        let (result, token) = InsertAffiliateSwift.parseReferralEnrolmentResponse(
            statusCode: 403, data: Data(#"{ "error": "In-app referrals are not enabled for this app.", "code": "PROGRAM_DISABLED" }"#.utf8))

        XCTAssertEqual(result.status, .error)
        XCTAssertEqual(result.errorCode, "PROGRAM_DISABLED")
        XCTAssertEqual(result.errorMessage, "In-app referrals are not enabled for this app.")
        XCTAssertNil(token)
    }

    func testErrorWithoutBodyUsesHttpStatus() {
        let (result, _) = InsertAffiliateSwift.parseReferralEnrolmentResponse(statusCode: 500, data: Data())

        XCTAssertEqual(result.status, .error)
        XCTAssertEqual(result.errorCode, "HTTP_500")
    }

    func testSuccessWithoutTokenIsAnError() {
        let (result, token) = InsertAffiliateSwift.parseReferralEnrolmentResponse(
            statusCode: 200, data: Data(#"{ "status": "created" }"#.utf8))

        XCTAssertEqual(result.status, .error)
        XCTAssertEqual(result.errorCode, "INVALID_RESPONSE")
        XCTAssertNil(token)
    }

    // MARK: - Referrer account (identity) body

    func testIdentityBodyIncludesSetFieldsAndDeviceId() {
        let body = InsertAffiliateSwift.buildReferrerIdentityBody(
            options: .init(appUserId: " rc_user_1 ", playPurchaseToken: "play.token-123"), deviceId: "A1B2C3")

        XCTAssertEqual(body, ["deviceId": "A1B2C3", "appUserId": "rc_user_1", "playPurchaseToken": "play.token-123"])
    }

    func testIdentityBodyLeavesOutUnsetAndEmptyFields() {
        XCTAssertEqual(InsertAffiliateSwift.buildReferrerIdentityBody(options: .init(), deviceId: "A1B2C3"),
                       ["deviceId": "A1B2C3"])
        XCTAssertEqual(InsertAffiliateSwift.buildReferrerIdentityBody(options: .init(appUserId: "  ", playPurchaseToken: ""), deviceId: ""),
                       [:])
    }

    func testIdentityDeviceIdMatchesInsertAffiliateIdentifier() {
        // Same id as the "{shortCode}-{deviceId}" identifier, so self-referral checks match.
        let deviceId = InsertAffiliateSwift.returnShortUniqueDeviceID()
        XCTAssertEqual(InsertAffiliateSwift.returnShortUniqueDeviceID(), deviceId)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "shortUniqueDeviceID"), deviceId)
    }

    // MARK: - Share text

    private let linkAffiliate = InsertAffiliateSwift.AffiliateDetails(
        affiliateName: "Jane", affiliateShortCode: "CODE1", deeplinkUrl: "https://insertaffiliate.link/abc")
    private let codeOnlyAffiliate = InsertAffiliateSwift.AffiliateDetails(
        affiliateName: "Jane", affiliateShortCode: "CODE1", deeplinkUrl: "CODE1")

    func testShareTextWithLinkUsesDefaultMessage() {
        let text = InsertAffiliateSwift.buildReferralShareText(affiliate: linkAffiliate, companyName: "Velvet", message: nil)
        XCTAssertEqual(text, "Try Velvet: https://insertaffiliate.link/abc")
    }

    func testShareTextForShortCodeOnly() {
        let text = InsertAffiliateSwift.buildReferralShareText(affiliate: codeOnlyAffiliate, companyName: "Velvet", message: nil)
        XCTAssertEqual(text, "Use my code CODE1 in Velvet")
    }

    func testShareTextAppendsLinkToCustomMessage() {
        let text = InsertAffiliateSwift.buildReferralShareText(affiliate: linkAffiliate, companyName: "Velvet", message: "Join me!")
        XCTAssertEqual(text, "Join me! https://insertaffiliate.link/abc")
    }

    func testShareTextFillsPlaceholders() {
        let text = InsertAffiliateSwift.buildReferralShareText(
            affiliate: linkAffiliate, companyName: "Velvet", message: "Code {code}, link {link}")
        XCTAssertEqual(text, "Code CODE1, link https://insertaffiliate.link/abc")

        let codeOnly = InsertAffiliateSwift.buildReferralShareText(
            affiliate: codeOnlyAffiliate, companyName: "Velvet", message: "Use {code} at {link}")
        XCTAssertEqual(codeOnly, "Use CODE1 at CODE1")
    }

    func testShareTextWithoutCompanyName() {
        let text = InsertAffiliateSwift.buildReferralShareText(affiliate: linkAffiliate, companyName: "", message: nil)
        XCTAssertEqual(text, "Try the app: https://insertaffiliate.link/abc")
    }

    // MARK: - Token storage

    func testTokenStoreSavesReplacesAndClearsPerCompany() throws {
        let companyId = "referrals-test-\(UUID().uuidString)"
        defer { ReferrerTokenStore.clear(companyId: companyId) }

        // Hostless SPM test bundles have no Keychain entitlement on the simulator.
        let probe: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.insertaffiliate.referrer.probe",
            kSecAttrAccount as String: companyId,
            kSecValueData as String: Data("x".utf8),
        ]
        let probeStatus = SecItemAdd(probe as CFDictionary, nil)
        SecItemDelete(probe as CFDictionary)
        if probeStatus == errSecMissingEntitlement {
            throw XCTSkip("Keychain is not available to this test bundle")
        }

        XCTAssertNil(ReferrerTokenStore.read(companyId: companyId))
        XCTAssertTrue(ReferrerTokenStore.save("first", companyId: companyId))
        XCTAssertTrue(ReferrerTokenStore.save("second", companyId: companyId))
        XCTAssertEqual(ReferrerTokenStore.read(companyId: companyId), "second")
        XCTAssertNil(ReferrerTokenStore.read(companyId: companyId + "-other"))

        ReferrerTokenStore.clear(companyId: companyId, ifToken: "first")
        XCTAssertEqual(ReferrerTokenStore.read(companyId: companyId), "second")
        ReferrerTokenStore.clear(companyId: companyId, ifToken: "second")
        XCTAssertNil(ReferrerTokenStore.read(companyId: companyId))

        XCTAssertTrue(ReferrerTokenStore.save("third", companyId: companyId))
        ReferrerTokenStore.clear(companyId: companyId)
        XCTAssertNil(ReferrerTokenStore.read(companyId: companyId))
    }

    func testRegisteredDeviceIdIsForgottenWhenTheTokenChanges() {
        let companyId = "referrals-test-\(UUID().uuidString)"
        defer { ReferrerTokenStore.clear(companyId: companyId) }

        XCTAssertNil(ReferrerTokenStore.registeredDeviceId(companyId: companyId))
        ReferrerTokenStore.markDeviceRegistered("ABC123", companyId: companyId)
        XCTAssertEqual(ReferrerTokenStore.registeredDeviceId(companyId: companyId), "ABC123")
        XCTAssertNil(ReferrerTokenStore.registeredDeviceId(companyId: companyId + "-other"))

        ReferrerTokenStore.save("new-token", companyId: companyId)
        XCTAssertNil(ReferrerTokenStore.registeredDeviceId(companyId: companyId))

        ReferrerTokenStore.markDeviceRegistered("ABC123", companyId: companyId)
        ReferrerTokenStore.clear(companyId: companyId)
        XCTAssertNil(ReferrerTokenStore.registeredDeviceId(companyId: companyId))
    }

    func testVerificationCodeIsNormalizedToAsciiDigits() {
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("123456"), "123456")
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode(" 123 456\n"), "123456")
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("123-456"), "123456")
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("\u{0661}\u{0662}\u{0663}\u{0664}\u{0665}\u{0666}"), "123456")
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("\u{06F7}\u{0968}\u{FF19}"), "729")
        // Numbers that aren't decimal digits are dropped.
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("\u{00BD}\u{2464}\u{00B2}1"), "1")
        XCTAssertEqual(InsertAffiliateSwift.normalizedVerificationCode("abc"), "")
    }

    @available(iOS 15.0, *)
    @MainActor
    func testVerifyNeedsExactlySixDigits() {
        let model = ReferAFriendModel(options: ReferAFriendOptions())
        model.code = "12345"
        XCTAssertFalse(model.hasCompleteCode)
        model.code = "123-456"
        XCTAssertTrue(model.hasCompleteCode)
        model.code = "\u{0661}\u{0662}\u{0663}\u{0664}\u{0665}\u{0666}"
        XCTAssertTrue(model.hasCompleteCode)
        model.code = "1234567"
        XCTAssertFalse(model.hasCompleteCode)
    }

    @available(iOS 15.0, *)
    @MainActor
    func testOnCloseFiresOncePerShowing() {
        var closes = 0
        let model = ReferAFriendModel(options: ReferAFriendOptions(onClose: { closes += 1 }))
        model.screenAppeared()
        // Close button, then the disappear that follows it.
        model.reportClose()
        model.reportClose()
        XCTAssertEqual(closes, 1)

        // Shown again, then swiped down.
        model.screenAppeared()
        model.reportClose()
        XCTAssertEqual(closes, 2)
    }

    @available(iOS 15.0, *)
    @MainActor
    func testUseADifferentEmailGoesBackToTheForm() {
        let model = ReferAFriendModel(options: ReferAFriendOptions(email: "typo@example.com"))
        model.step = .verifyCode
        model.code = "123"
        model.errorMessage = "That code is wrong or has expired."
        model.useDifferentEmail()
        XCTAssertEqual(model.step, .notEnrolled)
        XCTAssertEqual(model.code, "")
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.email, "typo@example.com")
    }

    @available(iOS 15.0, *)
    @MainActor
    func testLoadFailuresShowTheRightStep() throws {
        let disabled = try JSONDecoder().decode(InsertAffiliateSwift.ReferralProgramConfig.self,
                                                from: Data(#"{ "enabled": false }"#.utf8))
        let details = try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self,
                                               from: Data(#"{ "affiliateShortCode": "ABC123" }"#.utf8))
        let model = ReferAFriendModel(options: ReferAFriendOptions())

        model.apply(.serverError, config: nil)
        XCTAssertEqual(model.step, .loadFailed)
        XCTAssertEqual(model.errorMessage, "Something went wrong. Please try again.")

        model.errorMessage = nil
        model.apply(.networkError, config: nil)
        XCTAssertEqual(model.step, .loadFailed)
        XCTAssertEqual(model.errorMessage, model.message(for: "NETWORK_ERROR", fallback: nil))

        model.errorMessage = nil
        model.apply(.notConnected, config: disabled)
        XCTAssertEqual(model.step, .unavailable)

        model.errorMessage = nil
        model.apply(.notConnected, config: nil)
        XCTAssertEqual(model.step, .notEnrolled)
        XCTAssertNil(model.errorMessage)

        model.apply(.loaded(details), config: nil)
        XCTAssertEqual(model.step, .enrolled(details.affiliate))
    }

    func testTokenIsRejectedOnlyForTheServerTokenCodes() {
        func body(_ code: String) -> Data { Data(#"{"error":"x","code":"\#(code)"}"#.utf8) }
        XCTAssertTrue(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 401, data: body("INVALID_TOKEN")))
        XCTAssertTrue(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 404, data: body("AFFILIATE_NOT_FOUND")))
        // A proxy or an API without the route: not the token's fault.
        XCTAssertFalse(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 404, data: Data("Cannot GET /V1/sdk/affiliate/me".utf8)))
        XCTAssertFalse(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 401, data: Data()))
        XCTAssertFalse(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 404, data: body("INVALID_TOKEN")))
        XCTAssertFalse(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 401, data: body("AFFILIATE_NOT_FOUND")))
        XCTAssertFalse(InsertAffiliateSwift.isReferrerTokenRejected(statusCode: 500, data: body("INVALID_TOKEN")))
    }

    // MARK: - Drop-in screen helpers

    @available(iOS 15.0, *)
    @MainActor
    func testErrorMessagesAndColorParsing() {
        let model = ReferAFriendModel(options: ReferAFriendOptions())
        XCTAssertEqual(model.message(for: "INVALID_CODE", fallback: nil),
                       "That code is wrong or has expired. Check your email or send a new code.")
        XCTAssertEqual(model.message(for: "SOMETHING_NEW", fallback: "Server says no."), "Server says no.")
        // The SDK's developer message is logged, never shown.
        XCTAssertEqual(model.message(for: "NOT_INITIALIZED", fallback: "Call initialize with your company code first."),
                       "Referrals are not available in this app right now.")
        XCTAssertEqual(model.message(for: nil, fallback: nil), "Something went wrong. Please try again.")

        XCTAssertNotNil(ReferAFriendModel.color(hex: "#6A0DAD"))
        XCTAssertNil(ReferAFriendModel.color(hex: "6A0DAD"))
        XCTAssertNil(ReferAFriendModel.color(hex: "#GGGGGG"))
        XCTAssertNil(ReferAFriendModel.color(hex: ""))
    }

    @available(iOS 15.0, *)
    @MainActor
    func testScreenPassesReferrerAccountOptionsThrough() {
        let model = ReferAFriendModel(options: ReferAFriendOptions(
            email: "jane@example.com", appUserId: "rc_user_1", playPurchaseToken: "play.token-123"))
        XCTAssertEqual(model.accountOptions,
                       InsertAffiliateSwift.ReferrerAccountOptions(appUserId: "rc_user_1", playPurchaseToken: "play.token-123"))
        XCTAssertTrue(model.needsAccountSave)

        let noAccount = ReferAFriendModel(options: ReferAFriendOptions(appUserId: "  "))
        XCTAssertEqual(noAccount.accountOptions.playPurchaseToken, nil)
        XCTAssertFalse(noAccount.needsAccountSave)

        // The existing init still compiles without the new fields.
        let existing = ReferAFriendOptions(email: "a@b.com", name: "A", shareMessage: "Hi {link}", cornerRadius: 8) {}
        XCTAssertNil(existing.appUserId)
        XCTAssertNil(existing.playPurchaseToken)
    }

    @available(iOS 15.0, *)
    @MainActor
    func testPremiumUntilTextOnlyWhenInTheFuture() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let locale = Locale(identifier: "en_US")
        XCTAssertNil(ReferAFriendModel.premiumUntilText(nil, now: now, locale: locale))
        XCTAssertNil(ReferAFriendModel.premiumUntilText(now.addingTimeInterval(-60), now: now, locale: locale))

        let text = ReferAFriendModel.premiumUntilText(now.addingTimeInterval(86_400 * 10), now: now, locale: locale)
        XCTAssertNotNil(text)
        XCTAssertTrue(text?.hasPrefix("Free premium until ") == true)
        XCTAssertTrue(text?.contains("2026") == true)
    }

    @available(iOS 15.0, *)
    @MainActor
    func testStatsStripShowsOnlyTheEarningsTheCompanyShows() throws {
        func details(_ extra: String) throws -> InsertAffiliateSwift.MyAffiliateDetails {
            try JSONDecoder().decode(InsertAffiliateSwift.MyAffiliateDetails.self,
                                     from: Data("{ \"referralCount\": 4, \"totalEarned\": 12.5, \"currency\": \"USD\"\(extra) }".utf8))
        }
        let model = ReferAFriendModel(options: ReferAFriendOptions())
        let en = Locale(identifier: "en_US")

        // Older server: referrals and cash only.
        XCTAssertEqual(model.statItems(try details(""), locale: en).map(\.title), ["Referrals", "Earned"])

        let cashAndDays = try details(#", "rewardDaysEarned": 90, "earnedDisplay": { "cash": true, "days": true }"#)
        let all = model.statItems(cashAndDays, locale: en)
        XCTAssertEqual(all.map(\.title), ["Referrals", "Earned", "Days earned"])
        XCTAssertEqual(all.map(\.value), ["4", model.formattedEarned(cashAndDays), "90 days"])

        let daysOnly = model.statItems(try details(#", "rewardDaysEarned": 1, "earnedDisplay": { "cash": false, "days": true }"#), locale: en)
        XCTAssertEqual(daysOnly.map(\.title), ["Referrals", "Days earned"])
        XCTAssertEqual(daysOnly.last?.value, "1 day")

        let neither = model.statItems(try details(#", "earnedDisplay": { "cash": false, "days": false }"#), locale: en)
        XCTAssertEqual(neither.map(\.title), ["Referrals"])
        XCTAssertEqual(all.map(\.id), [.referrals, .earned, .days])

        // Two labels reworded to the same text still get distinct ids.
        let same = ReferAFriendModel(options: ReferAFriendOptions(
            strings: ReferralStrings(referralsLabel: "Total", earnedLabel: "Total")))
        XCTAssertEqual(Set(same.statItems(cashAndDays, locale: en).map(\.id)).count, 3)
    }

    @available(iOS 15.0, *)
    @MainActor
    func testDaysTextPluralisesAndHonoursOverrides() {
        let en = Locale(identifier: "en_US")
        XCTAssertEqual(ReferAFriendModel.daysText(0, dayTemplate: "{count} day", daysTemplate: "{count} days", locale: en), "0 days")
        XCTAssertEqual(ReferAFriendModel.daysText(1, dayTemplate: "{count} day", daysTemplate: "{count} days", locale: en), "1 day")
        XCTAssertEqual(ReferAFriendModel.daysText(1200, dayTemplate: "{count} day", daysTemplate: "{count} days", locale: en), "1,200 days")

        let model = ReferAFriendModel(options: ReferAFriendOptions(
            strings: ReferralStrings(daysEarnedLabel: "Dias ganados", dayUnit: "{count} dia", daysUnit: "{count} dias")))
        XCTAssertEqual(model.text(\.daysEarnedLabel), "Dias ganados")
        XCTAssertEqual(ReferAFriendModel.daysText(3, dayTemplate: model.text(\.dayUnit),
                                                  daysTemplate: model.text(\.daysUnit), locale: en), "3 dias")
    }

    @available(iOS 15.0, *)
    @MainActor
    func testCodeIsShownAndCopiedUnlessThePortalHidesIt() throws {
        func enrolled(link: String, showCode: String?) throws -> (ReferAFriendModel, InsertAffiliateSwift.AffiliateDetails) {
            let details = try JSONDecoder().decode(
                InsertAffiliateSwift.MyAffiliateDetails.self,
                from: Data(#"{ "affiliateShortCode": "ABC123", "deeplinkurl": "\#(link)" }"#.utf8))
            let config = try JSONDecoder().decode(
                InsertAffiliateSwift.ReferralProgramConfig.self,
                from: Data("{ \"enabled\": true\(showCode.map { ", \"showCode\": \($0)" } ?? "") }".utf8))
            let model = ReferAFriendModel(options: ReferAFriendOptions())
            model.apply(.loaded(details), config: config)
            return (model, details.affiliate)
        }

        // showCode true, or an older server that doesn't send it: the code shows and is copied.
        for flag in ["true", nil] {
            let (model, affiliate) = try enrolled(link: "https://x.link/abc", showCode: flag)
            XCTAssertTrue(model.showCodeBox)
            XCTAssertEqual(model.copyText(for: affiliate), "ABC123")
        }

        // Code hidden and a web link: only the link shows, and Copy copies it.
        let (hidden, hiddenAffiliate) = try enrolled(link: "https://x.link/abc", showCode: "false")
        XCTAssertFalse(hidden.showCodeBox)
        XCTAssertEqual(hidden.copyText(for: hiddenAffiliate), "https://x.link/abc")

        // Code hidden but no web link: the code is all there is to share, so it still shows.
        let (noLink, noLinkAffiliate) = try enrolled(link: "ABC123", showCode: "false")
        XCTAssertTrue(noLink.showCodeBox)
        XCTAssertEqual(noLink.copyText(for: noLinkAffiliate), "ABC123")
    }

    // MARK: - Screen labels

    @available(iOS 15.0, *)
    @MainActor
    func testLabelsUseTheEnglishDefaultsWhenNothingIsPassed() {
        let model = ReferAFriendModel(options: ReferAFriendOptions())
        XCTAssertEqual(model.text(\.emailLabel), "Email")
        XCTAssertEqual(model.text(\.nameLabel), "Name")
        XCTAssertEqual(model.text(\.joinButton), "Get my link")
        XCTAssertEqual(model.text(\.codeLabel), "6-digit code")
        XCTAssertEqual(model.text(\.verifyButton), "Verify")
        XCTAssertEqual(model.text(\.resendButton), "Send a new code")
        XCTAssertEqual(model.text(\.codeResentNotice), "We sent a new code. Check your email.")
        XCTAssertEqual(model.text(\.differentEmailButton), "Use a different email")
        XCTAssertEqual(model.text(\.codeLabelTitle), "Your code")
        XCTAssertEqual(model.text(\.copyButton), "Copy")
        XCTAssertEqual(model.text(\.copiedNotice), "Copied")
        XCTAssertEqual(model.text(\.copyLinkLabel), "Copy link")
        XCTAssertEqual(model.text(\.shareButton), "Share")
        XCTAssertEqual(model.text(\.referralsLabel), "Referrals")
        XCTAssertEqual(model.text(\.earnedLabel), "Earned")
        XCTAssertEqual(model.text(\.daysEarnedLabel), "Days earned")
        XCTAssertEqual(model.text(\.dayUnit), "{count} day")
        XCTAssertEqual(model.text(\.daysUnit), "{count} days")
        XCTAssertEqual(model.text(\.rewardsHeading), "Your rewards")
        XCTAssertEqual(model.text(\.redeemButton), "Redeem")
        XCTAssertEqual(model.text(\.dashboardLink), "Open my dashboard")
        XCTAssertEqual(model.text(\.closeButton), "Close")
        XCTAssertEqual(model.text(\.loading), "Loading...")
        XCTAssertEqual(model.text(\.tryAgainButton), "Try again")
        XCTAssertEqual(model.message(for: "AFFILIATE_LIMIT_REACHED", fallback: nil),
                       "The referral program is full right now. Please try again later.")
        XCTAssertEqual(model.message(for: "TOO_MANY_CODES", fallback: nil), model.message(for: "RATE_LIMITED", fallback: nil))
        XCTAssertEqual(model.message(for: "INVALID_EMAIL", fallback: nil), "Please enter a valid email address.")
    }

    @available(iOS 15.0, *)
    @MainActor
    func testOneOverriddenLabelLeavesTheRestAsDefaults() {
        let model = ReferAFriendModel(options: ReferAFriendOptions(strings: ReferralStrings(joinButton: "Obtener mi enlace")))
        XCTAssertEqual(model.text(\.joinButton), "Obtener mi enlace")
        XCTAssertEqual(model.text(\.emailLabel), "Email")
        XCTAssertEqual(model.text(\.shareButton), "Share")
        XCTAssertEqual(model.message(for: "INVALID_CODE", fallback: nil), ReferralStrings.defaultText(\.errorInvalidCode))
    }

    @available(iOS 15.0, *)
    @MainActor
    func testBlankOverridesFallBackToTheDefault() {
        let model = ReferAFriendModel(options: ReferAFriendOptions(
            strings: ReferralStrings(emailLabel: "", nameLabel: "   ", errorServer: "")))
        XCTAssertEqual(model.text(\.emailLabel), "Email")
        XCTAssertEqual(model.text(\.nameLabel), "Name")
        XCTAssertEqual(model.message(for: nil, fallback: nil), "Something went wrong. Please try again.")
    }

    @available(iOS 15.0, *)
    @MainActor
    func testPlaceholdersSurviveATranslation() {
        let model = ReferAFriendModel(options: ReferAFriendOptions(
            email: "jane@example.com",
            strings: ReferralStrings(
                codeSentNotice: "Ya tienes una cuenta. Enviamos un codigo de 6 digitos a {email}.",
                premiumUntil: "Premium gratis hasta {date}")))
        XCTAssertEqual(model.codeSentNotice, "Ya tienes una cuenta. Enviamos un codigo de 6 digitos a jane@example.com.")

        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let text = ReferAFriendModel.premiumUntilText(now.addingTimeInterval(86_400 * 10), now: now,
                                                      template: model.text(\.premiumUntil), locale: Locale(identifier: "en_US"))
        XCTAssertTrue(text?.hasPrefix("Premium gratis hasta ") == true)
        XCTAssertFalse(text?.contains("{date}") == true)

        // The default notice keeps its placeholder for the address the code went to.
        let english = ReferAFriendModel(options: ReferAFriendOptions(email: "jane@example.com"))
        XCTAssertEqual(english.codeSentNotice, "You already have an account. We emailed a 6-digit code to jane@example.com.")
    }
}
