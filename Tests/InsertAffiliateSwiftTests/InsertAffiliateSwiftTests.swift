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
        
        // Verify that the stored date is also set
        let storedDate = UserDefaults.standard.string(forKey: "affiliateStoredDate")
        XCTAssertNotNil(storedDate, "affiliateStoredDate should be stored when identifier is set.")
    }
    
    func testAffiliateStoredDateIsSetWhenIdentifierStored() {
        let referringLink = "TESTCODE"
        InsertAffiliateSwift.storeInsertAffiliateIdentifier(referringLink: referringLink)
        
        let storedDateString = UserDefaults.standard.string(forKey: "affiliateStoredDate")
        XCTAssertNotNil(storedDateString, "affiliateStoredDate should be set when identifier is stored.")
        
        let dateFormatter = ISO8601DateFormatter()
        let storedDate = dateFormatter.date(from: storedDateString!)
        XCTAssertNotNil(storedDate, "Stored date should be in valid ISO8601 format.")
        
        let timeDifference = abs(Date().timeIntervalSince(storedDate!))
        XCTAssertTrue(timeDifference < 5, "Stored date should be very recent (within 5 seconds).")
    }
    
    func testGetAffiliateStoredDate() {
        let referringLink = "TESTCODE"
        InsertAffiliateSwift.storeInsertAffiliateIdentifier(referringLink: referringLink)
        
        let retrievedDate = InsertAffiliateSwift.getAffiliateStoredDate()
        XCTAssertNotNil(retrievedDate, "Should be able to retrieve stored date.")
        
        let timeDifference = abs(Date().timeIntervalSince(retrievedDate!))
        XCTAssertTrue(timeDifference < 5, "Retrieved date should be very recent (within 5 seconds).")
    }
    
    func testGetAffiliateStoredDateWhenNoneExists() {
        let retrievedDate = InsertAffiliateSwift.getAffiliateStoredDate()
        XCTAssertNil(retrievedDate, "Should return nil when no date is stored.")
    }
    
    // Note: Timeout validation tests cannot be run in this test environment
    // as they require iOS availability and the state actor
    // These would need to be tested in an iOS simulator or device environment
}
