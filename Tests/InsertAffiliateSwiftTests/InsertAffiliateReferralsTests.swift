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

        ReferrerTokenStore.clear(companyId: companyId)
        XCTAssertNil(ReferrerTokenStore.read(companyId: companyId))
    }

    // MARK: - Drop-in screen helpers

    @available(iOS 15.0, *)
    @MainActor
    func testErrorMessagesAndColorParsing() {
        XCTAssertEqual(ReferAFriendModel.message(for: "INVALID_CODE", fallback: nil),
                       "That code is wrong or has expired. Check your email or send a new code.")
        XCTAssertEqual(ReferAFriendModel.message(for: "SOMETHING_NEW", fallback: "Server says no."), "Server says no.")
        XCTAssertEqual(ReferAFriendModel.message(for: nil, fallback: nil), "Something went wrong. Please try again.")

        XCTAssertNotNil(ReferAFriendModel.color(hex: "#6A0DAD"))
        XCTAssertNil(ReferAFriendModel.color(hex: "6A0DAD"))
        XCTAssertNil(ReferAFriendModel.color(hex: "#GGGGGG"))
        XCTAssertNil(ReferAFriendModel.color(hex: ""))
    }
}
