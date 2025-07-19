# InsertAffiliateSwift SDK for iOS

![Version](https://img.shields.io/badge/version-1.0.0-brightgreen) ![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)

## Overview

The **InsertAffiliateSwift SDK** is designed for iOS applications, providing seamless integration with the [Insert Affiliate platform](https://insertaffiliate.com). 
The InsertAffiliateSwift SDK simplifies affiliate marketing for iOS apps with in-app-purchases, allowing developers to create a seamless user experience for affiliate tracking and monetisation.

### Features

- **Unique Device ID**: Creates a unique ID to anonymously associate purchases with users for tracking purposes.
- **Affiliate Identifier Management**: Set and retrieve the affiliate identifier based on user-specific links.
- **In-App Purchase (IAP) Initialisation**: Easily reinitialise in-app purchases with the option to validate using an affiliate identifier.
- **Offer Code Handling**: Fetch offer codes from the Insert Affiliate API and open redeem URLs directly in the App Store.

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

### 3. Offer Codes

Offer Codes allow you to retrieve and store discount codes for users who access an affiliate's link or enter a short code. This provides affiliates with a compelling incentive to promote your app, as you can present these discounts to users at the appropriate time in your app flow [(learn more)](https://docs.insertaffiliate.com/offer-codes). 

The SDK will automatically fetch and store any available offer codes, making them accessible through the `iOSOfferCode` property for use in your app's redemption flow.

#### Using Offer Codes with Deep Links

To retrieve and store an Offer Code from an affiliate link, pass the deep link (from your Branch or other deep link provider) to:

```swift
// Store the offer code when the deep link is clicked
InsertAffiliateSwift.retrieveAndStoreOfferCode(affiliateLink: "your_affiliate_link")

// Later in your app, access the stored offer code when needed
if let storedOfferCode = InsertAffiliateSwift.iOSOfferCode {
    print("Retrieved stored offer code: \(storedOfferCode)")
    // Present the offer code to the user or use it in your redemption flow
}
```

#### Accessing the Stored Offer Code

Once an offer code has been retrieved and stored, you can access it using the public property:

```swift
if let storedOfferCode = InsertAffiliateSwift.iOSOfferCode {
    print("Current stored offer code: \(storedOfferCode)")
    // Use the offer code as needed in your app
}


#### Branch.io Example
```swift
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
      if let referringLink = params?["~referring_link"] as? String {
        // Store the offer code when deep link is opened
        InsertAffiliateSwift.retrieveAndStoreOfferCode(affiliateLink: referringLink)

        // Other code required for Insert Affiliate in the other listed steps...
      }
      return true
    }
  }
}

// Later in your app (e.g., during checkout or subscription flow)
func presentOfferCodeIfAvailable() {
    if let storedOfferCode = InsertAffiliateSwift.iOSOfferCode {
        print("Found stored offer code: \(storedOfferCode)")
        // Present the offer code to the user or redirect to App Store redemption
    }
}
```


#### Using Offer Codes with Short Codes

Offer codes also work with short codes. After a user enters a short code, you can retrieve and store the associated offer code:

```swift
// First, set the short code (this is typically done when user enters it in your UI)
InsertAffiliateSwift.setShortCode(shortCode: "USER123456")

// Then retrieve and store the offer code
InsertAffiliateSwift.retrieveAndStoreOfferCode(affiliateLink: "USER123456")

// Later in your app, check for and use the stored offer code
if let storedOfferCode = InsertAffiliateSwift.iOSOfferCode {
    print("Found offer code for user: \(storedOfferCode)")
    // Use the offer code in your app's flow - perhaps during checkout or subscription
}
```


