# InsertAffiliateSwift SDK for iOS

![Version](https://img.shields.io/badge/version-1.0.0-brightgreen) ![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange) ![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue)

The official iOS SDK for [Insert Affiliate](https://insertaffiliate.com) - track affiliate-driven in-app purchases and reward your partners automatically.

**What does this SDK do?** It connects your iOS app to Insert Affiliate's platform, enabling you to track which affiliates drive subscriptions and automatically pay them commissions when users make in-app purchases.

## 📋 Table of Contents

- [Quick Start (5 Minutes)](#-quick-start-5-minutes)
- [Essential Setup](#%EF%B8%8F-essential-setup)
  - [1. Initialize the SDK](#1-initialize-the-sdk)
  - [2. Configure In-App Purchase Verification](#2-configure-in-app-purchase-verification)
  - [3. Set Up Deep Linking](#3-set-up-deep-linking)
- [Verify Your Integration](#-verify-your-integration)
- [Advanced Features](#-advanced-features)
- [Troubleshooting](#-troubleshooting)
- [Support](#-support)

---

## 🚀 Quick Start (5 Minutes)

Get up and running with minimal code to validate the SDK works before tackling IAP and deep linking setup.

### Prerequisites

- **iOS 13.0+** and **Swift 5.0+**
- **Xcode 12.0+**
- **Company Code** from your [Insert Affiliate dashboard](https://app.insertaffiliate.com/settings)

### Installation

**Step 1:** Open your Xcode project

**Step 2:** Go to `File > Add Packages`

**Step 3:** Enter the repository URL:
```
https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK.git
```

**Step 4:** Select the branch `main` and confirm

**Alternative: Swift Package Manager**

Add to your `Package.swift`:
```swift
.package(url: "https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK.git", branch: "main")
```

### Your First Integration

Add this minimal code to your `AppDelegate.swift` to test the SDK:

```swift
import InsertAffiliateSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize SDK with verbose logging (recommended during setup)
        InsertAffiliateSwift.initialize(
            companyCode: "YOUR_COMPANY_CODE",  // Get from https://app.insertaffiliate.com/settings
            verboseLogging: true                // Enable verbose logging for setup
        )
        return true
    }
}
```

**For SwiftUI apps:**

```swift
import SwiftUI
import InsertAffiliateSwift

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        InsertAffiliateSwift.initialize(companyCode: "YOUR_COMPANY_CODE", verboseLogging: true)
        return true
    }
}
```

**Expected Console Output:**

When the SDK initializes successfully, you'll see logs confirming initialization:

```
[InsertAffiliateSwift] SDK initialized with company code: YOUR_COMPANY_CODE
[InsertAffiliateSwift] Verbose logging enabled
```

✅ **If you see these logs, the SDK is working!** Now proceed to Essential Setup below.

⚠️ **Disable verbose logging in production** by setting `verboseLogging: false` or omitting it.

---

## ⚙️ Essential Setup

Complete these three required steps to start tracking affiliate-driven purchases.

### 1. Initialize the SDK

The SDK must be initialized in your `AppDelegate` before using any features. You've already done the basic initialization above, but here are additional options:

#### Basic Initialization (Recommended for Getting Started)

```swift
// Minimal setup with verbose logging enabled (recommended during development)
InsertAffiliateSwift.initialize(companyCode: "YOUR_COMPANY_CODE", verboseLogging: true)
```

<details>
<summary><strong>Advanced Initialization Options</strong> (click to expand)</summary>

```swift
// With Insert Links enabled (for Insert Affiliate's built-in deep linking)
InsertAffiliateSwift.initialize(
    companyCode: "YOUR_COMPANY_CODE",
    verboseLogging: true,                      // Enable verbose logging
    insertLinksEnabled: true,                  // Enable Insert Links
    insertLinksClipboardEnabled: true,         // Enable clipboard access (triggers permission prompt)
    affiliateAttributionActiveTime: 604800     // Optional: 7 days attribution timeout (default: no timeout)
)
```

**Parameters:**
- `verboseLogging`: Shows detailed logs for debugging (disable in production)
- `insertLinksEnabled`: Set to `true` if using Insert Links, `false` if using Branch/AppsFlyer
- `insertLinksClipboardEnabled`: Enables clipboard-based attribution for Insert Links. When enabled:
  - **How it works**: When a user clicks an Insert Link, the affiliate identifier is automatically copied to their clipboard
  - **What the SDK does**: On app launch, the SDK checks the clipboard for Insert Affiliate identifiers and applies them
  - **Why it's useful**: This massively increases attribution success rate and accuracy by providing a reliable fallback when direct deep linking fails (e.g., user manually opens app later, deep link doesn't work, app wasn't installed yet, etc.)
  - **User experience**: iOS will show a one-time permission prompt: "[Your App] would like to paste from [App Name]"
  - **Recommendation**: Strongly recommended for maximum attribution accuracy, though users will see the clipboard permission prompt
- `affiliateAttributionActiveTime`: How long affiliate attribution lasts in seconds (0 = never expires)

</details>

---

### 2. Configure In-App Purchase Verification

**Insert Affiliate requires a receipt verification method to validate purchases.** Choose **ONE** of the following:

| Method | Best For | Setup Time | Complexity |
|--------|----------|------------|------------|
| [**RevenueCat**](#option-1-revenuecat-recommended) | Most developers, managed infrastructure | ~10 min | ⭐ Simple |
| [**Iaptic**](#option-2-iaptic) | Custom requirements, direct control | ~15 min | ⭐⭐ Medium |
| [**App Store Direct**](#option-3-app-store-direct-beta) | No 3rd party fees (subscriptions only) | ~20 min | ⭐⭐ Medium |
| [**Apphud**](#option-4-apphud) | Alternative managed infrastructure | ~10 min | ⭐ Simple |

<details open>
<summary><h4>Option 1: RevenueCat (Recommended)</h4></summary>

**Step 1: Code Setup**

Complete the [RevenueCat SDK installation](https://www.revenuecat.com/docs/getting-started/installation/ios) first, then modify your `AppDelegate.swift`:

```swift
import SwiftUI
import RevenueCat
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Purchases.configure(withAPIKey: "YOUR_REVENUE_CAT_API_KEY")

    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Purchases.shared.attribution.setAttributes(["insert_affiliate": applicationUsername])
    }

    return true
  }
}
```

Replace `YOUR_REVENUE_CAT_API_KEY` with your **RevenueCat API Key** from [here](https://www.revenuecat.com/docs/welcome/authentication).

**Step 2: Webhook Setup**

1. In RevenueCat, [create a new webhook](https://www.revenuecat.com/docs/integrations/webhooks)
2. Configure webhook settings:
   - **Webhook URL**: `https://api.insertaffiliate.com/v1/api/revenuecat-webhook`
   - **Event Type**: "All events"
3. In your [Insert Affiliate dashboard](https://app.insertaffiliate.com/settings):
   - Set **In-App Purchase Verification** to `RevenueCat`
   - Copy the `RevenueCat Webhook Authentication Header` value
4. Back in RevenueCat webhook config:
   - Paste the authentication header value into the **Authorization header** field

✅ **RevenueCat setup complete!** Now skip to [Step 3: Set Up Deep Linking](#3-set-up-deep-linking)

</details>

<details>
<summary><h4>Option 2: Iaptic</h4></summary>

**Step 1: Code Setup**

Complete the [Iaptic account setup](https://www.iaptic.com/documentation/setup/ios) and [SDK installation](https://github.com/iridescent-dev/iap-swift-lib). Then modify your `AppDelegate.swift`:

```swift
import SwiftUI
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    InsertAffiliateSwift.initialize(companyCode: "YOUR_COMPANY_CODE")

    // Define products
    let iapProductsArray = [
      IAPProduct(
        productIdentifier: "YOUR_APPLE_IAP_SUBSCRIPTION_ID",
        productType: .autoRenewableSubscription
      )
    ]

    // Reinitialise In-App Purchases
    InAppPurchase.stop()
    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      InAppPurchase.initialize(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName=YOUR_IAPTIC_APP_NAME&apiKey=YOUR_IAPTIC_PUBLIC_KEY",
        applicationUsername: applicationUsername
      )
    } else {
      InAppPurchase.initialize(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName=YOUR_IAPTIC_APP_NAME&apiKey=YOUR_IAPTIC_PUBLIC_KEY"
      )
    }
    return true
  }
}
```

Replace:
- `YOUR_IAPTIC_APP_NAME` with your [Iaptic App Name](https://www.iaptic.com/account)
- `YOUR_IAPTIC_PUBLIC_KEY` with your [Iaptic Public Key](https://www.iaptic.com/settings)

**Step 2: Webhook Setup**

1. Open the [Insert Affiliate settings](https://app.insertaffiliate.com/settings):
   - Set the In-App Purchase Verification method to `Iaptic`
   - Copy the `Iaptic Webhook URL` and `Iaptic Webhook Sandbox URL`
2. Go to [Iaptic Settings](https://www.iaptic.com/settings):
   - Paste the Webhook URLs into the corresponding fields
   - Click **Save Settings**
3. Complete the [Iaptic App Store Server Notifications setup](https://www.iaptic.com/documentation/setup/ios-subscription-status-url)

✅ **Iaptic setup complete!** Now proceed to [Step 3: Set Up Deep Linking](#3-set-up-deep-linking)

</details>

<details>
<summary><h4>Option 3: App Store Direct (Beta)</h4></summary>

**Step 1: Apple App Store Notification Setup**

Visit [our docs](https://docs.insertaffiliate.com/direct-store-purchase-integration#1-apple-app-store-server-notifications) and complete the required App Store Server to Server Notifications setup.

**Step 2: Implementing Purchases**

```swift
// Within the function where you are making the purchase...
func purchase(productIdentifier: String) async {
    do {
      // Replace your product.purchase() with the lines below
      let token = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction()
      // Optional override: Use your own UUID for the purchase token
      // let token = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction(
      //     overrideUUIDString: "YOUR_OWN_UUID"
      // )
      let result = try await product.purchase(options: token.map { [.appAccountToken($0)] } ?? [])
    }
}
```

✅ **App Store Direct setup complete!** Now proceed to [Step 3: Set Up Deep Linking](#3-set-up-deep-linking)

</details>

<details>
<summary><h4>Option 4: Apphud</h4></summary>

**Step 1: Code Setup**

Complete the [Apphud Quickstart and Setup](https://docs.apphud.com/docs/quickstart). Then modify your `AppDelegate.swift`:

```swift
import SwiftUI
import ApphudSDK
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Apphud.start(apiKey: "YOUR_APPHUD_KEY")

    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Apphud.setUserProperty(key: .init("insert_affiliate"), value: applicationUsername, setOnce: false)
    }

    return true
  }
}
```

Replace `YOUR_APPHUD_KEY` with your **Apphud API Key**.

**Step 2: Webhook Setup**

1. Open the [Insert Affiliate settings](https://app.insertaffiliate.com/settings):
   - Set the In-App Purchase Verification method to `Apphud`
   - Copy the `Apphud Webhook URL`
2. Go to the [Apphud Dashboard](https://app.apphud.com/):
   - Navigate to **Settings** → **iOS App Settings**
   - Paste the webhook URL into the `Proxy App Store server notifications to this URL` field
   - Click **Save**

✅ **Apphud setup complete!** Now proceed to [Step 3: Set Up Deep Linking](#3-set-up-deep-linking)

</details>

---

### 3. Set Up Deep Linking

**Deep linking lets affiliates share unique links that track users to your app.** Choose **ONE** deep linking provider:

| Provider | Best For | Complexity | Setup Guide |
|----------|----------|------------|-------------|
| [**Insert Links**](#option-1-insert-links-simplest) | Simple setup, no 3rd party | ⭐ Simple | [View](#option-1-insert-links-simplest) |
| [**Branch.io**](#option-2-branchio) | Robust attribution, deferred deep linking | ⭐⭐ Medium | [View](#option-2-branchio) |
| [**AppsFlyer**](#option-3-appsflyer) | Enterprise analytics, comprehensive attribution | ⭐⭐ Medium | [View](#option-3-appsflyer) |

<details open>
<summary><h4>Option 1: Insert Links (Simplest)</h4></summary>

Insert Links is Insert Affiliate's built-in deep linking solution—no third-party SDK required.

**Prerequisites:**
- Complete the [Insert Links setup](https://docs.insertaffiliate.com/insert-links) in the Insert Affiliate dashboard

**Code Implementation:**

```swift
import UIKit
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    // Initialize SDK with Insert Links enabled
    InsertAffiliateSwift.initialize(
      companyCode: "YOUR_COMPANY_CODE",
      verboseLogging: true,              // Enable for debugging
      insertLinksEnabled: true,          // Enable Insert Links
      insertLinksClipboardEnabled: false // Set to true if attribution accuracy is most important (triggers clipboard permission prompt)
    )

    // Set up callback for affiliate identifier changes
    InsertAffiliateSwift.setInsertAffiliateIdentifierChangeCallback { identifier in
      if let identifier = identifier {
        print("Affiliate identifier: \(identifier)")

        // If using RevenueCat, update attributes here
        Purchases.shared.attribution.setAttributes(["insert_affiliate": identifier])

        // If using Apphud, update property here
        // Apphud.setUserProperty(key: .init("insert_affiliate"), value: identifier, setOnce: false)
      }
    }

    // Handle deep link from app launch
    if let url = launchOptions?[.url] as? URL {
      InsertAffiliateSwift.handleInsertLinks(url)
    }
    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    InsertAffiliateSwift.handleInsertLinks(url)
    return true
  }

  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
      InsertAffiliateSwift.handleInsertLinks(url)
    }
    return true
  }
}
```

**SwiftUI - On Open URL:**

```swift
import InsertAffiliateSwift
import RevenueCat
import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
           ContentView()
               .onOpenURL(perform: { url in
                    // Handle InsertAffiliate deep links
                    if InsertAffiliateSwift.handleInsertLinks(url) {
                        // Update RevenueCat attribution with the new affiliate info
                        if let affiliateIdentifier = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
                            Purchases.shared.attribution.setAttributes(["insert_affiliate": affiliateIdentifier])
                        }
                    }
               })
        }
    }
}
```

**Testing Deep Links:**

```bash
# Test with your iOS URL scheme from Insert Affiliate dashboard
xcrun simctl openurl booted "YOUR_IOS_URL_SCHEME://TEST_SHORT_CODE"

# Test universal link
xcrun simctl openurl booted "https://api.insertaffiliate.com/V1/YOUR_COMPANY_CODE/TEST_SHORT_CODE"
```

✅ **Insert Links setup complete!** Skip to [Verify Your Integration](#-verify-your-integration)

</details>

<details>
<summary><h4>Option 2: Branch.io</h4></summary>

Branch.io provides robust attribution and deferred deep linking capabilities.

**Key Integration Steps:**
1. Install and configure [Branch SDK for iOS](https://help.branch.io/developers-hub/docs/ios-basic-integration)
2. Extract `~referring_link` from Branch callback
3. Pass to Insert Affiliate SDK using `setInsertAffiliateIdentifier()`

📖 **[View complete Branch.io integration guide →](docs/deep-linking-branch.md)**

Includes full examples for:
- RevenueCat integration
- Apphud integration
- Iaptic integration
- App Store Direct integration

✅ **After completing Branch setup**, skip to [Verify Your Integration](#-verify-your-integration)

</details>

<details>
<summary><h4>Option 3: AppsFlyer</h4></summary>

AppsFlyer provides enterprise-grade analytics and comprehensive attribution.

**Key Integration Steps:**
1. Install and configure [AppsFlyer SDK for iOS](https://dev.appsflyer.com/hc/docs/ios-sdk-reference-getting-started)
2. Create AppsFlyer OneLink in dashboard
3. Extract deep link from `onAppOpenAttribution()` callback
4. Pass to Insert Affiliate SDK using `setInsertAffiliateIdentifier()`

📖 **[View complete AppsFlyer integration guide →](docs/deep-linking-appsflyer.md)**

Includes full examples for:
- RevenueCat integration
- Iaptic integration
- App Store Direct integration
- Deferred deep linking setup

✅ **After completing AppsFlyer setup**, proceed to [Verify Your Integration](#-verify-your-integration)

</details>

---

## ✅ Verify Your Integration

Before going live, verify everything works correctly:

### Integration Checklist

- [ ] **SDK Initializes**: Check console for `SDK initialized with company code` log
- [ ] **Affiliate Identifier Stored**: Click a test affiliate link and verify identifier is stored
- [ ] **Purchase Tracked**: Make a test purchase and verify transaction is sent to Insert Affiliate

### Testing Commands

**Test Deep Link (via Simulator):**

```bash
# Replace with your actual deep link URL
xcrun simctl openurl booted "https://your-app.onelink.me/abc123"
```

**Check Stored Affiliate Identifier:**

```swift
if let affiliateId = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
    print("Current affiliate ID: \(affiliateId)")
}
```

**Expected Output:** `Current affiliate ID: AFFILIATE1-a1b2c3`

### Common Setup Issues

| Issue | Solution |
|-------|----------|
| "Company code is not set" | Ensure `initialize()` is called in `AppDelegate` before any other SDK methods |
| "No affiliate identifier found" | User must click an affiliate link before making a purchase |
| Deep link opens browser instead of app | Verify associated domains in Xcode project and deep linking provider dashboard |
| Purchase not tracked | Check webhook configuration in IAP verification platform |

---

## 🔧 Advanced Features

<details>
<summary><h3>Event Tracking (Beta)</h3></summary>

Track custom events beyond purchases (e.g., signups, referrals) to incentivize affiliates for specific actions.

```swift
// Track custom event (affiliate identifier must be set first)
InsertAffiliateSwift.trackEvent(eventName: "user_signup")
```

**Use Cases:**
- Pay affiliates for signups instead of purchases
- Track trial starts, content unlocks, or other conversions

</details>

<details>
<summary><h3>Short Codes</h3></summary>

Short codes are unique, 3-25 character alphanumeric identifiers that affiliates can share (e.g., "SAVE20" in a TikTok video description).

**Validate and Store Short Code:**

```swift
Task {
    let isValid = await InsertAffiliateSwift.setShortCode(shortCode: "SAVE20")
    if isValid {
        print("Short code is valid!")
        // Show success message to user
    } else {
        print("Invalid short code")
        // Show error message
    }
}
```

**Get Affiliate Details Without Setting:**

```swift
if let details = await InsertAffiliateSwift.getAffiliateDetails(affiliateCode: "SAVE20") {
    print("Affiliate Name: \(details.affiliateName)")
    print("Short Code: \(details.affiliateShortCode)")
    print("Deep Link: \(details.deeplinkUrl)")
}
```

Learn more: [Short Codes Documentation](https://docs.insertaffiliate.com/short-codes)

</details>

<details>
<summary><h3>Dynamic Offer Codes / Discounts</h3></summary>

Automatically apply discounts or trials when users come from specific affiliates.

**How It Works:**
1. Configure an offer code modifier in your [Insert Affiliate dashboard](https://app.insertaffiliate.com/affiliates) (e.g., `_oneWeekFree`)
2. SDK automatically fetches and stores the modifier when affiliate identifier is set
3. Use the modifier to construct dynamic product IDs

**Quick Example:**

```swift
var dynamicProductIdentifier: String {
    let baseProductId = "oneMonthSubscription"

    if let offerCode = InsertAffiliateSwift.OfferCode {
        let cleanOfferCode = offerCode.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        return "\(baseProductId)\(cleanOfferCode)"
    }

    return baseProductId
}
```

📖 **[View complete Dynamic Offer Codes guide →](docs/dynamic-offer-codes.md)**

Includes full examples for:
- App Store Connect setup
- RevenueCat integration with dynamic product selection
- Native StoreKit 2 integration
- Testing and troubleshooting

</details>

<details>
<summary><h3>Attribution Timeout Control</h3></summary>

Control how long affiliate attribution remains active after a user clicks a link (e.g., 7-day attribution window).

**Set Timeout During Initialization:**

```swift
// 7-day attribution window (604800 seconds)
InsertAffiliateSwift.initialize(
    companyCode: "YOUR_COMPANY_CODE",
    affiliateAttributionActiveTime: 604800
)
```

**Check Attribution Validity:**

```swift
let isValid = await InsertAffiliateSwift.isAffiliateAttributionValid()
if isValid {
    // Attribution is still active
} else {
    // Attribution expired
}
```

**Common Timeout Values:**
- 1 day: `86400`
- 7 days: `604800` (recommended)
- 30 days: `2592000`
- No timeout: omit parameter (default)

**Get Attribution Date:**

```swift
if let storedDate = InsertAffiliateSwift.getAffiliateStoredDate() {
    print("Affiliate stored on: \(storedDate)")
}
```

</details>

---

## 🔍 Troubleshooting

### Initialization Issues

**Error:** "Company code is not set"
- **Cause:** SDK not initialized or `initialize()` called after other SDK methods
- **Solution:** Call `InsertAffiliateSwift.initialize()` in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` before any other SDK methods

### Deep Linking Issues

**Problem:** Deep link opens browser instead of app
- **Cause:** Missing or incorrect associated domains, or URL scheme not configured
- **Solution:**
  - Verify associated domains in Xcode project match your deep linking provider's domain
  - Add URL scheme to Info.plist
  - For universal links, ensure apple-app-site-association file is properly configured

**Problem:** "No affiliate identifier found"
- **Cause:** User hasn't clicked an affiliate link yet
- **Solution:** Ensure users come from affiliate links before purchases. Test with simulator:
  ```bash
  xcrun simctl openurl booted "YOUR_DEEP_LINK_URL"
  ```

### Purchase Tracking Issues

**Problem:** Purchases not appearing in Insert Affiliate dashboard
- **Cause:** Webhook not configured or affiliate identifier not passed to IAP platform
- **Solution:**
  - Verify webhook URL and authorization headers are correct
  - For RevenueCat: Confirm `insert_affiliate` attribute is set before purchase
  - For Iaptic/App Store Direct: Check that affiliate identifier exists when purchase is made
  - Enable verbose logging and check console for errors

### Verbose Logging

Enable detailed logs during development to diagnose issues:

```swift
InsertAffiliateSwift.initialize(companyCode: "YOUR_COMPANY_CODE", verboseLogging: true)
```

**Important:** Disable verbose logging in production builds.

### Getting Help

- 📖 [Documentation](https://docs.insertaffiliate.com)
- 💬 [Dashboard Support](https://app.insertaffiliate.com/help)
- 🐛 [Report Issues](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK/issues)

---

## 📚 Support

- **Documentation**: [docs.insertaffiliate.com](https://docs.insertaffiliate.com)
- **Dashboard Support**: [app.insertaffiliate.com/help](https://app.insertaffiliate.com/help)
- **Issues**: [GitHub Issues](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK/issues)
- **Company Code**: [Get yours from Settings](https://app.insertaffiliate.com/settings)

---

**Need help getting started?** Check out our [quickstart guide](https://docs.insertaffiliate.com) or [contact support](https://app.insertaffiliate.com/help).
