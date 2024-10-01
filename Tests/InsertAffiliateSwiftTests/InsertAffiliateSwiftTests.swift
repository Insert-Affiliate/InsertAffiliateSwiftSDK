import Testing
import XCTest
@testable import InsertAffiliateSwift
import InAppPurchaseLib

final class InsertAffiliateSwiftTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "shortUniqueDeviceID")
        UserDefaults.standard.removeObject(forKey: "insertAffiliateIdentifier")
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "shortUniqueDeviceID")
        UserDefaults.standard.removeObject(forKey: "insertAffiliateIdentifier")
    }

    func testReturnShortUniqueDeviceID_existingID() {
        UserDefaults.standard.set("123ABC", forKey: "shortUniqueDeviceID")
        let result = InsertAffiliateSwift.returnShortUniqueDeviceID()
        XCTAssertEqual(result, "123ABC", "Should return existing short unique device ID.")
    }

    func testReturnShortUniqueDeviceID_newID() {
        let result = InsertAffiliateSwift.returnShortUniqueDeviceID()
        XCTAssertNotNil(result, "Should generate a new short unique device ID.")
        XCTAssertEqual(result.count, 6, "Generated ID should have a length of 6 characters.")
        
        let storedID = UserDefaults.standard.string(forKey: "shortUniqueDeviceID")
        XCTAssertEqual(result, storedID, "Stored ID should match the returned ID.")
    }
    
    func testSetInsertAffiliateIdentifier() {
        let referringLink = "https://example.com"
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink)
        
        let result = UserDefaults.standard.string(forKey: "insertAffiliateIdentifier")
        XCTAssertNotNil(result, "insertAffiliateIdentifier should be stored.")
        XCTAssertTrue(result!.contains(referringLink), "Stored identifier should contain the referring link.")
        XCTAssertTrue(result!.count > referringLink.count, "Stored identifier should append the unique device ID.")
    }
    
    func testReturnInsertAffiliateIdentifier() {
        UserDefaults.standard.set("https://example.com/123ABC", forKey: "insertAffiliateIdentifier")
        
        let result = InsertAffiliateSwift.returnInsertAffiliateIdentifier()
        XCTAssertEqual(result, "https://example.com/123ABC", "Should return the correct affiliate identifier.")
    }
    
    func testReturnInsertAffiliateIdentifier_nil() {
        let result = InsertAffiliateSwift.returnInsertAffiliateIdentifier()
        XCTAssertNil(result, "Should return nil when no affiliate identifier is stored.")
    }
    
    func testReinitializeIAP_withApplicationUsername_noCrash() {
        // Mocking the return of insert affiliate identifier
        UserDefaults.standard.set("affiliate_user", forKey: "insertAffiliateIdentifier")
        
        let mockProducts = [IAPProduct]()
        
        // Assert that the app doesn't crash during the call
        XCTAssertNoThrow(
            InsertAffiliateSwift.reinitializeIAP(iapProductsArray: mockProducts, validatorUrlString: "https://validator.com"),
            "reinitializeIAP should not crash with application username"
        )
    }

    func testReinitializeIAP_withoutApplicationUsername_noCrash() {
        // Ensure no affiliate identifier is saved
        UserDefaults.standard.removeObject(forKey: "insertAffiliateIdentifier")
        
        let mockProducts = [IAPProduct]()
        
        // Assert that the app doesn't crash during the call
        XCTAssertNoThrow(
            InsertAffiliateSwift.reinitializeIAP(iapProductsArray: mockProducts, validatorUrlString: "https://validator.com"),
            "reinitializeIAP should not crash without application username"
        )
    }
}
