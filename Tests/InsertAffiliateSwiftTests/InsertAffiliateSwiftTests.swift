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
}
