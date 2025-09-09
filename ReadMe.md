# InsertAffiliateSwift SDK for iOS

![Version](https://img.shields.io/badge/version-1.0.0-brightgreen) ![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)

## Overview

The **InsertAffiliateSwift SDK** is designed for iOS applications, providing seamless integration with the [Insert Affiliate platform](https://insertaffiliate.com). 
The InsertAffiliateSwift SDK simplifies affiliate marketing for iOS apps with in-app-purchases, allowing developers to create a seamless user experience for affiliate tracking and monetisation.

### Features

- **Unique Device ID**: Creates a unique ID to anonymously associate purchases with users for tracking purposes.
- **Affiliate Identifier Management**: Set and retrieve the affiliate identifier based on user-specific links.
- **In-App Purchase (IAP) Initialisation**: Easily reinitialise in-app purchases with the option to validate using an affiliate identifier.
- **Discounts for End Users**: Fetch discount modifiers from the Insert Affiliate API.

## Getting Started
To get started with the InsertAffiliateSwift SDK:

1. [Install the SDK via Swift Package Manager](#installation)
2. [Initialise the SDK in your AppDelegate or SwiftUI @main entry point](#basic-usage)
3. [Set up in-app purchases (Required)](#in-app-purchase-setup-required)
4. [Set up deep linking (Required)](#deep-link-setup-required)
5. [Use additional features like event tracking based on your app's requirements.](#additional-features)


Refer to the below Examples section for detailed implementation steps.

## Installation

To integrate the InsertAffiliateSwift SDK into your iOS app:

1. Open your Xcode project.
2. Go to File > Add Packages.
3. Enter the repository URL: https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK.git
4. Select the branch main.
5. Confirm and integrate the package.

```swift
.package(url: "https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK.git", branch: "main")
```

### Troubleshooting Tips:

If you encounter build errors, ensure your project uses Swift 5.0+ and targets iOS 13.0 or later.
For Xcode-specific issues, clean the build folder using ```Shift + Command + K``` and rebuild the project.

## Basic Usage
### Import the SDK

Import the SDK in your Swift files:

```swift
import InsertAffiliateSwift
```

### Initialisation in AppDelegate

To ensure proper initialisation of the **InsertAffiliateSwift SDK**, you should call the `initialise` method early in your app's lifecycle, typically within the `AppDelegate`.

- Replace `{{ your_company_code }}` with the unique company code associated with your Insert Affiliate account. You can find this code in your dashboard under [Settings](http://app.insertaffiliate.com/settings).

```swift
import InsertAffiliateSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")
        return true
    }
}
```

### Verbose Logging (Optional)

By default, the SDK operates silently to avoid interrupting the user experience. However, you can enable verbose logging to see visual confirmation when affiliate attribution is processed. This is particularly useful for debugging during development or TestFlight testing.

#### Enable Verbose Logging

```swift
import InsertAffiliateSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Enable verbose logging for debugging/testing
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}", verboseLogging: true)
        return true
    }
}
```

#### SwiftUI Initialization with Verbose Logging

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
        // Enable verbose logging for TestFlight builds
        #if TESTFLIGHT
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}", verboseLogging: true)
        #else
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")
        #endif
        return true
    }
}
```

**When verbose logging is enabled:**
- A success alert will display when a deep link is processed
- The alert shows the extracted user code, affiliate email, and company information
- Attribution tracking continues to work normally in the background

**When verbose logging is disabled (default):**
- Deep links are processed silently without any user interface interruption
- All attribution tracking works normally in the background

**Recommendation**: Enable verbose logging only for development and TestFlight builds, and disable it for production App Store releases.

### Insert Link and Clipboard Control (BETA)

We are currently beta testing our in-house deep linking provider, Insert Links, which generates links for use with your affiliates.

For larger projects where accuracy is critical, we recommend using established third-party deep linking platforms to generate the links you use within Insert Affiliate - such as Appsflyer or Branch.io, as described in the rest of this README.

If you encounter any issues while using Insert Links, please raise an issue on this GitHub repository or contact us directly at michael@insertaffiliate.com

#### Insert Link Initialization

```swift
import InsertAffiliateSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Enable Insert Affiliate deep link handling
        InsertAffiliateSwift.initialize(
          companyCode: "{{ your_company_code }}", 
          insertLinksEnabled: true,
          insertLinksClipboardEnabled: true,
        )
        return true
    }
}
```

**When to use `insertLinksEnabled`:**
- Set to `true` (default: `false`) if you are using Insert Affiliate's built-in deep link and universal link handling (Insert Links)
- Set to `false` if you are using an external provider for deep links

**When to use `insertLinksClipboardEnabled`:**
- Set to `true` (default: `false`) if you are using Insert Affiliate's built-in deep links (Insert Links) **and** would like to improve the effectiveness of our deep links through the clipboard
- **Important caveat**: This will trigger a system prompt asking the user for permission to access the clipboard when the SDK initializes


#### Combined Configuration

```swift
import InsertAffiliateSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        InsertAffiliateSwift.initialize(
            companyCode: "{{ your_company_code }}",
            verboseLogging: true, // Enable for debugging
            insertLinksEnabled: true, // Enable Insert Links
            insertLinksClipboardEnabled: false // Disable clipboard access to avoid permission prompt
        )
        return true
    }
}
```




## In-App Purchase Setup [Required]
Insert Affiliate requires a Receipt Verification platform to validate in-app purchases. You must choose **one** of our supported partners:
- [RevenueCat](https://www.revenuecat.com/)
- [Iaptic](https://www.iaptic.com/account)
- [App Store Direct Integration](#app-store-direct-integration)
- [Apphud](https://apphud.com/)

### Option 1: RevenueCat Integration
#### 1. Code Setup
First, complete the [RevenueCat SDK installation](https://www.revenuecat.com/docs/getting-started/installation/ios). Then modify your `AppDelegate.swift`:

```swift
import SwiftUI
import RevenueCat
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Purchases.configure(withAPIKey: "{{ your_revenue_cat_api_key }}")

    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Purchases.shared.attribution.setAttributes(["insert_affiliate": applicationUsername])
    }

    return true
  }
}
```
Replace `{{ your_revenue_cat_api_key }}` with your **RevenueCat API Key**. You can find this [here](https://www.revenuecat.com/docs/welcome/authentication).

#### 2. Webhook Setup

1. Go to RevenueCat and [create a new webhook](https://www.revenuecat.com/docs/integrations/webhooks)

2. Configure the webhook with these settings:
   - Webhook URL: `https://api.insertaffiliate.com/v1/api/revenuecat-webhook`
   - Authorization header: Use the value from your Insert Affiliate dashboard (you'll get this in step 4)
   - Set "Event Type" to "All events"

3. In your [Insert Affiliate dashboard settings](https://app.insertaffiliate.com/settings):
   - Navigate to the verification settings
   - Set the in-app purchase verification method to `RevenueCat`

4. Back in your Insert Affiliate dashboard:
   - Locate the `RevenueCat Webhook Authentication Header` value
   - Copy this value
   - Paste it as the Authorization header value in your RevenueCat webhook configuration

### Option 2: Iaptic Integration
#### 1. Code Setup

First, complete the [Iaptic account setup](https://www.iaptic.com/documentation/setup/ios) and [SDK installation.](https://github.com/iridescent-dev/iap-swift-lib) Then modify your ```AppDelegate.swift```:

```swift
import SwiftUI
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    // Step 1: Define products
    let iapProductsArray = [
      IAPProduct(
        productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
        productType: .autoRenewableSubscription
      )
    ]

    // Step 2: Reinitialise In-App Purchases
    InAppPurchase.stop()
    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      InAppPurchase.initialize(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
        applicationUsername: applicationUsername
      )
    } else {
      InAppPurchase.initialize(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}"
      )
    }
    return true
  }
}
```
Replace the following:
- `{{ your_iaptic_app_name }}` with your [Iaptic App Name](https://www.iaptic.com/account)
- `{{ your_iaptic_public_key }}` with your [Iaptic Public Key](https://www.iaptic.com/settings)

#### 2. Webhook Setup

1. Open the [Insert Affiliate settings](https://app.insertaffiliate.com/settings):
  - Navigate to the Verification Settings section
  - Set the In-App Purchase Verification method to `Iaptic`
  - Copy the `Iaptic Webhook URL` and the `Iaptic Webhook Sandbox URL`- you'll need it in the next step.
2. Go to the [Iaptic Settings](https://www.iaptic.com/settings)
- Paste the copied `Iaptic Webhook URL` into the `Webhook URL` field
- Paste the copied `Iaptic Webhook Sandbox URL` into the `Sandbox Webhook URL` field
- Click **Save Settings**.
3. Check that you have completed the [Iaptic setup for the App Store Server Notifications](https://www.iaptic.com/documentation/setup/ios-subscription-status-url)

### Option 3: App Store Direct Integration

Our direct App Store integration is currently in beta and currently supports subscriptions only. **Consumables and one-off purchases are not yet supported** due to App Store server-to-server notification limitations.

We plan to release support for consumables and one-off purchases soon. In the meantime, you can use a receipt verification platform from the other integration options.

#### 1. Apple App Store Notification Setup
To proceed, visit [our docs](https://docs.insertaffiliate.com/direct-store-purchase-integration#1-apple-app-store-server-notifications) and complete the required setup steps to set up App Store Server to Server Notifications.

#### 2. Implementing Purchases

```swift
// Step 1: Initialise purchases, retrieve the product

// Step 2: Within the function where you are making the purchase...
func purchase(productIdentifier: String) async {
    do {
      // Step 3: Replace your product.purchase() with the lines below
      let token = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction() 
      // Optional override: Use your own UUID for the purchase token
      // let token = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction(
      //     overrideUUIDString: "{{your_own_uuid}}"
      // )
      let result = try await product.purchase(options: token.map { [.appAccountToken($0)] } ?? [])
    }
}
```

### Option 4: Apphud Integration
#### 1. Code Setup
First, complete the [Apphud Quickstart and Setup](https://docs.apphud.com/docs/quickstart). Then modify your ```AppDelegate.swift```:

```swift
import SwiftUI
import ApphudSDK
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Apphud.start(apiKey: "{{ your_apphud_key }}")


    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Apphud.setUserProperty(key: .init("insert_affiliate"), value: applicationUsername, setOnce: false)
    }

    return true
  }
}
```
- Replace {{ your_apphud_key }} with your **Apphud API Key**.

#### 2. Webhook Setup
1. Open the [Insert Affiliate settings](https://app.insertaffiliate.com/settings):
   - Navigate to the Verification Settings section
   - Set the In-App Purchase Verification method to `Apphud`
   - Copy the `Apphud Webhook URL`- you'll need it in the next step.
2. Go to the [Apphud Dashboard](https://app.apphud.com/)
3. Navigate to **Settings** -> **iOS App Settings:**
- Paste the copied `Apphud Webhook URL` into the `Proxy App Store server notifications to this URL` field
- Click **Save**.


## Deep Link Setup [Required]
Insert Affiliate requires a Deep Linking platform to create links for your affiliates. Our platform works with **any** deep linking provider, and you only need to follow these steps:
1. **Create a deep link** in your chosen third-party platform and pass it to our dashboard when an affiliate signs up. 
2. **Handle deep link clicks** in your app by passing the clicked link:
   ```swift
   InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: "{{ link }}")
   ```
3. **Integrate with a Receipt Verification platform** by using the result from `setInsertAffiliateIdentifier` to log in or set your application’s username. Examples below include [**Iaptic**](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK?tab=readme-ov-file#example-with-iaptic), [**RevenueCat**](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK?tab=readme-ov-file#example-with-revenuecat) and [**Direct App Store integration**](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK?tab=readme-ov-file#example-with-app-store-direct-integration).

### Deep Linking with Insert Links

Insert Links by Insert Affiliate supports direct deep linking into your app. This allows you to track affiliate attribution when end users are referred to your app by clicking on one of your affiliates Insert Links.

#### Initial Setup

Before you can use Insert Links, you must complete the setup steps in [our docs](https://docs.insertaffiliate.com/insert-links)

1. **Initialization** of the Insert Affiliate SDK with Insert Links

You must enable *insertLinksEnabled* when [initialising our SDK](https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK/tree/feature/deeplink-2?tab=readme-ov-file#insert-link-initialization)

2. **Handle Insert Links** in your AppDelegate

The SDK provides a single `handleInsertLinks` method that automatically detects and handles different URL types. 

```swift
import UIKit
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool { 
    InsertAffiliateSwift.setInsertAffiliateIdentifierChangeCallback { identifier in
      if let identifier = identifier {
        // *** Required if using RevenueCat *** //
        Purchases.shared.attribution.setAttributes(["insert_affiliate": identifier]) 
        // *** End of RevenueCat section *** //

        // *** Required if using Apphud *** //
        Apphud.setUserProperty(key: .init("insert_affiliate"), value: shortCode, setOnce: false) 
        // *** End of Apphud Section *** //

        /// *** Required only if you're using Iaptic ** //
        InAppPurchase.initialize( 
          iapProducts: iapProductsArray,
          validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
          applicationUsername: affiliateIdentifier
        )
        // *** End of Iaptic Section ** //
      }
    }

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

### 3. SwiftUI - On Open URL
For SwiftUI apps, you can handle Insert Links directly using the .onOpenURL modifier. This allows you to capture and process deep links while the app is already running.

#### SwiftUI App example

```swift
import InsertAffiliateSwift
import RevenueCat
import SwiftUI

@main
struct InsertAffiliateAppApp: App {
    @StateObject private var viewModel = InAppPurchaseViewModel()

    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
           ContentView()
                .environmentObject(viewModel)
                .onAppear {
                  //...
                }
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

> **Note**: The SwiftUI `.onOpenURL` approach is recommended for modern SwiftUI apps as it's cleaner and more declarative. The AppDelegate approach is still needed for handling universal links and launch-time deep linksz


#### Integration Examples

##### With RevenueCat

```swift
import RevenueCat
import InsertAffiliateSwift

// In your AppDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  if InsertAffiliateSwift.handleInsertLinks(url) {
    // Update RevenueCat attribution
    if let affiliateIdentifier = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Purchases.shared.attribution.setAttributes(["insert_affiliate": affiliateIdentifier])
    }
    return true
  }
  return false
}
```

##### With Iaptic

```swift
import InAppPurchaseLib
import InsertAffiliateSwift

// In your AppDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  if InsertAffiliateSwift.handleInsertLinks(url) {
    // Reinitialize Iaptic with affiliate identifier
    if let affiliateIdentifier = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      let iapProductsArray = [
        IAPProduct(
          productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
          productType: .autoRenewableSubscription
        )
      ]
      
      InAppPurchase.stop()
      InAppPurchase.initialize(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
        applicationUsername: affiliateIdentifier
      )
    }
    return true
  }
  return false
}
```

#### Testing Deep Links

Test your deep link integration using the iOS Simulator:

```bash
# Test with your iOS URL scheme from Insert Affiliate dashboard
xcrun simctl openurl booted "{{ your_iOS_URL_Scheme }}://{{ test_short_code }}"

# Test universal link
xcrun simctl openurl booted "https://api.insertaffiliate.com/V1/{{ your_company_code }}/{{ test_short_code }}"
```

Replace `{{ your_iOS_URL_Scheme }}` with the URL scheme from your [Insert Affiliate dashboard](https://app.insertaffiliate.com/settings), and `{{ test_short_code }}` with a test short code.

**Example:**
```bash
# If your iOS URL scheme is "ia-clbz8jf3unfp5frzjxby3d3xj382"
xcrun simctl openurl booted "ia-clbz8jf3unfp5frzjxby3d3xj382://eedwftx2po"
```

**Debugging Deep Links:** Enable [verbose logging](#verbose-logging-optional) during development to see visual confirmation when deep links are processed successfully. This shows an alert with the extracted user code, affiliate email, and company information.

#### Retrieving Affiliate Information

After handling a deep link, you can retrieve the affiliate information:

```swift
// Get the affiliate identifier
if let affiliateIdentifier = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
  print("Affiliate ID: \(affiliateIdentifier)")
}
```

### Deep Linking with Branch.io
To set up deep linking with Branch.io, follow these steps:

1. Create a deep link in Branch and pass it to our dashboard when an affiliate signs up.
    - Example: [Create Affiliate](https://docs.insertaffiliate.com/create-affiliate).
2. Modify Your Deep Link Handling in AppDelegate.swift
    - After setting up your Branch integration, add the following code to initialise the Insert Affiliate SDK in your iOS app:


#### Example with RevenueCat
```swift
import SwiftUI
import BranchSDK
import RevenueCat
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
          if let referringLink = params?["~referring_link"] as? String {
            InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { result in
                guard let shortCode = result else {
                    return
                }

                Purchases.shared.attribution.setAttributes(["insert_affiliate": shortCode])
          }
        }
        return true
    }
}
```

#### Example with Apphud
```swift
import SwiftUI
import BranchSDK
import ApphudSDK
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
          if let referringLink = params?["~referring_link"] as? String {
            InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { result in
                guard let shortCode = result else {
                    return
                }

                Apphud.setUserProperty(key: .init("insert_affiliate"), value: shortCode, setOnce: false)
          }
        }
        return true
    }
}
```

#### Example with Iaptic
```swift
import SwiftUI
import BranchSDK
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
      if let referringLink = params?["~referring_link"] as? String {
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { result in
          guard let shortCode = result else {
            return
          }

          let iapProductsArray = [
            IAPProduct(
              productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
              productType: .autoRenewableSubscription
            )
          ]

          InAppPurchase.stop()
          if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
            InAppPurchase.initialize(
              iapProducts: iapProductsArray,
              validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
              applicationUsername: applicationUsername
            )
          } else {
            InAppPurchase.initialize(
              iapProducts: iapProductsArray,
              validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}"
            )
          }
      }
    }
    return true
  }
}
```
Replace the following:
- `{{ your_iaptic_app_name }}` with your [Iaptic App Name](https://www.iaptic.com/account)
- `{{ your_iaptic_public_key }}` with your [Iaptic Public Key](https://www.iaptic.com/settings)

#### Example with App Store Direct Integration

```swift
import SwiftUI
import BranchSDK
import StoreKit
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Branch.getInstance().initSession(launchOptions: launchOptions) { params, _ in
      if let referringLink = params?["~referring_link"] as? String {
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { _ in }
      }
    }
    return true
  }
}

```

### Deep Linking with AppsFlyer
To set up deep linking with AppsFlyer, follow these steps:

1. Create a [OneLink](https://support.appsflyer.com/hc/en-us/articles/208874366-Create-a-OneLink-link-for-your-campaigns) in AppsFlyer and pass it to our dashboard when an affiliate signs up.
   - Example: [Create Affiliate](https://docs.insertaffiliate.com/create-affiliate).
2. Initialize AppsFlyer SDK and set up deep link handling in your app.

#### Platform Setup
Complete the deep linking setup for AppsFlyer by following their official documentation:
- [AppsFlyer Deferred Deep Link Integration Guide](https://dev.appsflyer.com/hc/docs/deeplinkintegrate)

This covers all platform-specific configurations including:
- iOS: Info.plist configuration, AppDelegate setup, and universal links
- Testing and troubleshooting

#### Example with RevenueCat

```swift
import SwiftUI
import AppsFlyerLib
import RevenueCat
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Initialize Insert Affiliate SDK
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")
        
        // Configure AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "{{ your_appsflyer_dev_key }}"
        AppsFlyerLib.shared().appleAppID = "{{ your_ios_app_id }}"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
        
        return true
    }
    
    // Handle URL schemes and universal links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity)
        return true
    }
    
    // MARK: - AppsFlyer Delegate Methods
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        handleAppsFlyerDeepLink(attributionData)
    }
    
    func onDeepLink(_ deepLink: AppsFlyerDeepLink) {
        let attributionData = deepLink.clickEvent ?? [:]
        handleAppsFlyerDeepLink(attributionData)
    }
    
    private func handleAppsFlyerDeepLink(_ attributionData: [AnyHashable: Any]) {
        let dict = attributionData as? [String: Any] ?? [:]
        let referringLink = (dict["link"] as? String) ?? (dict["deep_link_value"] as? String) ?? (dict["af_dp"] as? String)
        
        guard let link = referringLink else { return }
        
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: link) { shortCode in
            guard let shortCode = shortCode else { return }
            
            Purchases.shared.attribution.setAttributes(["insert_affiliate": shortCode])
        }
    }
}
```

#### Example with Iaptic

```swift
import SwiftUI
import AppsFlyerLib
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Initialize Insert Affiliate SDK
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")
        
        // Configure AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "{{ your_appsflyer_dev_key }}"
        AppsFlyerLib.shared().appleAppID = "{{ your_ios_app_id }}"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
        
        return true
    }
    
    // Handle URL schemes and universal links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity)
        return true
    }
    
    // MARK: - AppsFlyer Delegate Methods
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        handleAppsFlyerDeepLink(attributionData)
    }
    
    func onDeepLink(_ deepLink: AppsFlyerDeepLink) {
        let attributionData = deepLink.clickEvent ?? [:]
        handleAppsFlyerDeepLink(attributionData)
    }
    
    private func handleAppsFlyerDeepLink(_ attributionData: [AnyHashable: Any]) {
        let dict = attributionData as? [String: Any] ?? [:]
        let referringLink = (dict["link"] as? String) ?? (dict["deep_link_value"] as? String) ?? (dict["af_dp"] as? String)
        
        guard let link = referringLink else { return }
        
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: link) { shortCode in
            guard let shortCode = shortCode else { return }
            
            // Reinitialize Iaptic with affiliate identifier
            let iapProducts = [
                IAPProduct(
                    productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
                    productType: .autoRenewableSubscription
                )
            ]
            
            InAppPurchase.stop()
            InAppPurchase.initialize(
                iapProducts: iapProducts,
                validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_public_key }}",
                applicationUsername: shortCode
            )
        }
    }
}
```
Replace the following:
- `{{ your_iaptic_app_name }}` with your [Iaptic App Name](https://www.iaptic.com/account)
- `{{ your_iaptic_public_key }}` with your [Iaptic Public Key](https://www.iaptic.com/settings)

#### Example with App Store Direct Integration

```swift
import SwiftUI
import AppsFlyerLib
import StoreKit
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Initialize Insert Affiliate SDK
        InsertAffiliateSwift.initialize(companyCode: "{{ your_company_code }}")
        
        // Configure AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "{{ your_appsflyer_dev_key }}"
        AppsFlyerLib.shared().appleAppID = "{{ your_ios_app_id }}"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
        
        return true
    }
    
    // Handle URL schemes and universal links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity)
        return true
    }
    
    // MARK: - AppsFlyer Delegate Methods
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        handleAppsFlyerDeepLink(attributionData)
    }
    
    func onDeepLink(_ deepLink: AppsFlyerDeepLink) {
        let attributionData = deepLink.clickEvent ?? [:]
        handleAppsFlyerDeepLink(attributionData)
    }
    
    private func handleAppsFlyerDeepLink(_ attributionData: [AnyHashable: Any]) {
        let dict = attributionData as? [String: Any] ?? [:]
        let referringLink = (dict["link"] as? String) ?? (dict["deep_link_value"] as? String) ?? (dict["af_dp"] as? String)
        
        guard let link = referringLink else { return }
        
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: link) { _ in
            // Affiliate identifier is stored automatically for App Store Direct integration
        }
    }
}
```

### Deep Linking with Other Platforms
Insert Affiliate supports all other deep linking providers. The general steps remain the same:

1. Generate a **deep link** using your provider and pass it to our dashboard.
2. **Extract and pass the deep link** to Insert Affiliate inside your app’s deep link handling logic.

Refer to your deep linking provider’s documentation for specific instructions on how to retrieve the deep link URL as demonstrated above for Branch.io.

## Additional Features
### 1. Event Tracking (Beta)

The **InsertAffiliateSwift SDK** now includes a beta feature for event tracking. Use event tracking to log key user actions such as signups, purchases, or referrals. This is useful for:
- Understanding user behaviour.
- Measuring the effectiveness of marketing campaigns.
- Incentivising affiliates for designated actions being taken by the end users, rather than just in app purchases (i.e. pay an affilaite for each signup).

At this stage, we cannot guarantee that this feature is fully resistant to tampering or manipulation.

#### Using `trackEvent`

To track an event, use the `trackEvent` function. Make sure to set an affiliate identifier first; otherwise, event tracking won’t work. Here’s an example:

```swift
InsertAffiliateSwift.trackEvent(eventName: "your_event_name")
```

### 2. Short Codes (Beta)

### What are Short Codes?

Short codes are unique, 3 to 25 character alphanumeric identifiers that affiliates can use to promote products or subscriptions. These codes are ideal for influencers or partners, making them easier to share than long URLs.

**Example Use Case**: An influencer promotes a subscription with the short code "JOIN123456" within their TikTok video's description. When users enter this code within your app during sign-up or before purchase, the app tracks the subscription back to the influencer for commission payouts.

For more information, visit the [Insert Affiliate Short Codes Documentation](https://docs.insertaffiliate.com/short-codes).

### Setting a Short Code

Use the `setShortCode` method to associate a short code with an affiliate. This is ideal for scenarios where users enter the code via an input field, pop-up, or similar UI element.

Short codes must meet the following criteria:
- Between **3 and 25 characters long**.
- Contain only **letters and numbers** (alphanumeric characters).
- Replace {{ user_entered_short_code }} with the short code the user enters through your chosen input method, i.e. an input field / pop up element

```swift
InsertAffiliateSwift.setShortCode(shortCode: "{{user_entered_short_code}}")
```

#### Example Integration
Below is an example SwiftUI implementation where users can enter a short code, which will be validated and associated with the affiliate's account:

```swift
import SwiftUI
import InsertAffiliateSwift

struct ShortCodeView: View {
  @State private var shortCode: String = ""
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 20) {
      Text("Enter your Short Code")
        .font(.headline)

      TextField("Short Code", text: $shortCode)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .autocapitalization(.allCharacters)
        .padding()

      Button(action: {
          setShortCode()
      }) {
        Text("Set Short Code")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.subheadline)
      }
    }
    .padding()
  }

  func setShortCode() {
    let trimmedShortCode = shortCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    guard trimmedShortCode.count == 10 else {
      errorMessage = "Short code must be exactly 10 characters long."
      return
    }

    let alphanumericSet = CharacterSet.alphanumerics
    guard trimmedShortCode.unicodeScalars.allSatisfy({ alphanumericSet.contains($0) }) else {
      errorMessage = "Short code must contain only letters and numbers."
      return
    }

    // Set the short code using InsertAffiliateSwift
    InsertAffiliateSwift.setShortCode(shortCode: trimmedShortCode)
    errorMessage = nil
  }
}

struct ShortCodeView_Previews: PreviewProvider {
  static var previews: some View {
    ShortCodeView()
  }
}
```

### 3. Discounts for Users → Offer Codes / Dynamic Product IDs

The InsertAffiliateSwift SDK lets you pass modifiers based on if the app was installed due to the work of an affiliate for your in app purchases. These modifiers can be used swap your in app purchase being offered to the end user out for one with a discount or trial offer, similar to giving the end user an offer code.

**How It Works**

When someone clicks an affiliate link or enters a short code linked to an offer (set up in the Insert Affiliate Dashboard), the SDK fills in InsertAffiliateSwift.OfferCode with the right modifier (like _oneWeekFree). You can then add this to your regular product ID to load the correct version of the subscription in your app.

**Insert Affiliate Setup Instructions**

1. Go to your Insert Affiliate dashboard at [app.insertaffiliate.com/affiliates](https://app.insertaffiliate.com/affiliates)
2. Select the affiliate you want to configure
3. Click "View" to access the affiliate's settings
4. Assign an **iOS IAP Modifier** to the affiliate (e.g., `_oneWeekFree`, `_threeMonthsFree`)
5. Save the settings

Once configured, when users click that affiliate's links or enter their short codes, your app will automatically receive the modifier and can load the appropriate discounted product.

**Implementation Examples**

#### RevenueCat Example

```swift
class InAppPurchaseViewModel: ObservableObject {
    @Published var products: [StoreProduct] = []
    
    var dynamicProductIdentifier: String {
        let baseProductId = "oneMonthSubscriptionTwo"
        
        if let offerCode = InsertAffiliateSwift.OfferCode {
            let cleanOfferCode = offerCode.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return "\(baseProductId)\(cleanOfferCode)"
        }
        
        return baseProductId
    }
    
    func loadProducts() {
        Purchases.shared.getProducts([dynamicProductIdentifier]) { products in
            DispatchQueue.main.async {
                self.products = products
                print("Loaded product: \(self.dynamicProductIdentifier)")
            }
        }
    }
}
```

#### Native StoreKit 2 Example

```swift
@MainActor
class InAppPurchaseViewModel: ObservableObject {
    @Published var products: [String: Product] = [:]
    private let baseProductIdentifier = "oneMonthSubscriptionTwo"
    
    var dynamicProductIdentifier: String {
        if let offerCode = InsertAffiliateSwift.OfferCode, !offerCode.isEmpty {
            let cleanOfferCode = offerCode.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return "\(baseProductIdentifier)\(cleanOfferCode)"
        }
        return baseProductIdentifier
    }
    
    func fetchProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: [dynamicProductIdentifier])
            products = Dictionary(uniqueKeysWithValues: fetchedProducts.map { ($0.id, $0) })
            print("Loaded product: \(dynamicProductIdentifier)")
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    func purchase(productIdentifier: String) async {
        guard let product = products[productIdentifier] else { return }

        do {
            let userAccountToken = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction()
            // Optional override: Use your own UUID for the purchase token
            // let token = await InsertAffiliateSwift.returnUserAccountTokenAndStoreExpectedTransaction(
            //     overrideUUIDString: "{{your_own_uuid}}"
            // )
            let result = try await product.purchase(options: userAccountToken.map { [.appAccountToken($0)] } ?? [])
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    print("Purchase successful: \(transaction.id)")
                    await transaction.finish()
                }
            case .userCancelled:
                print("Purchase cancelled")
            case .pending:
                print("Purchase pending")
            default:
                break
            }
        } catch {
            print("Purchase error: \(error.localizedDescription)")
        }
    }
}
```

#### Purchase View Integration

This view uses the `dynamicProductIdentifier` which automatically includes any offer code modifiers from the Insert Affiliate SDK, ensuring users see the correct promotional product:

```swift
struct PurchaseView: View {
    @StateObject private var viewModel = InAppPurchaseViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            if let product = viewModel.products[viewModel.dynamicProductIdentifier] {
                Text(product.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Price: \(product.price)")
                    .font(.headline)
                
                Text("Product ID: \(product.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Purchase") {
                    Task {
                        await viewModel.purchase(productIdentifier: product.id)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Text("Product not found: \(viewModel.dynamicProductIdentifier)")
                
                Button("Refresh Products") {
                    Task {
                        await viewModel.fetchProducts()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchProducts() // Load dynamic products with offer codes
            }
        }
    }
}
```

**Example Product Identifiers**

- Base product: `oneMonthSubscriptionTwo`
- With introductory discount: `oneMonthSubscriptionTwo_oneWeekFree`
- With different offer: `oneMonthSubscriptionTwo_threeMonthsFree`

**Best Practices**

- **Call in Purchase Views**: Always implement this logic in views where users can make purchases
- **Handle Both Cases**: Ensure your app works whether an offer code is present or not
- **Fallback**: Have a fallback to your base product if the dynamic product isn't found

**App Store Connect Configuration**

Make sure you have created the corresponding subscription products in App Store Connect:
- Your base subscription (e.g., `oneMonthSubscriptionTwo`)
- Promotional offer variants (e.g., `oneMonthSubscriptionTwo_oneWeekFree`)
