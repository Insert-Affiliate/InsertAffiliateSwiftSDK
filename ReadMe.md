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
5. Use additional features like affiliate tracking based on your app's requirements.


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
        InsertAffiliateSwift.initialise(companyCode: "{{ your_company_code }}")
        return true
    }
}
```

## In-App Purchase Setup [Required]
To use Insert Affiliate, you must first set up a Receipt Verification platform to validate in-app purchases through one of our partners: [RevenueCat](https://www.revenuecat.com/) or [Iaptic](https://www.iaptic.com/account). 

These platforms ensure secure and reliable validation, enabling seamless integration with Insert Affiliate.

### Option 1: Setup with RevenueCat
After completing your account setup and SDK setup with [RevenueCat](https://www.revenuecat.com/docs/getting-started/installation/ios), the follow code changes are required to integrate RevenueCat with Insert Affiliate:

- Replace `{{ your_revenue_cat_api_key }}` with your **RevenueCat API Key**. You can find this [here](https://www.revenuecat.com/docs/welcome/authentication).


#### Modify Your `AppDelegate.swift` to Initialise In-App Purchases with Insert Affiliate:
```swift
import SwiftUI
import RevenueCat
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Purchases.configure(withAPIKey: "{{ your_revenue_cat_api_key }}")

    if let applicationUsername = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
      Purchases.shared.logIn(applicationUsername) { (customerInfo, created, error) in
      }
    }

    return true
  }
}
```

### Option 2: Setup with Iaptic
After completing your account setup with Iaptic, the follow code changes are required to integrate Iaptic with Insert Affiliate:

##### Modify Your `AppDelegate.swift` to Initialise In-App Purchases with Insert Affiliate:

Here's the example code with placeholders for you to swap out:

- Replace `{{ your_iaptic_app_name }}` with your **Iaptic App Name**. You can find this [here](https://www.iaptic.com/account).
- Replace `{{ your_iaptic_public_key }}` with your **Iaptic Public Key**. You can find this [here](https://www.iaptic.com/settings).

```swift
import SwiftUI
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
    InsertAffiliateSwift.initialise(companyCode: "{{ your_company_code }}")

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
      InAppPurchase.initialise(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
        applicationUsername: applicationUsername
      )
    } else {
      InAppPurchase.initialise(
        iapProducts: iapProductsArray,
        validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}"
      )
    }
    return true
  }
}
```

## Deep Link Setup [Required]

### Step 1: Add the Deep Linking Platform Dependency

In this example, the deep linking functionality is implemented using [Branch.io](https://dashboard.branch.io/).

Any alternative deep linking platform can be used by passing the referring link to ```InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: "{{ link }}")``` as in the below Branch.io example

### Step 2: Modify Your Deep Link initSession function in `AppDelegate.swift`

After setting up your Branch integration, add the following code to initialise the Insert Affiliate SDK in your iOS app.

#### Step 2a: Example with RevenueCat
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

          Purchases.shared.logIn(shortCode) { (customerInfo, created, error) in
            // customerInfo updated for my_app_user_id. If you are having issues, you can investigate here.
          }
      }
    }
    return true
  }
}
```

#### Step 2b: Example with Iaptic
- Replace `{{ your_iaptic_app_name }}` with your **Iaptic App Name**. You can find this [here](https://www.iaptic.com/account).
- Replace `{{ your_iaptic_public_key }}` with your **Iaptic Public Key**. You can find this [here](https://www.iaptic.com/settings).

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
            InAppPurchase.initialise(
              iapProducts: iapProductsArray,
              validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
              applicationUsername: applicationUsername
            )
          } else {
            InAppPurchase.initialise(
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

Short codes are unique, 10-character alphanumeric identifiers that affiliates can use to promote products or subscriptions. These codes are ideal for influencers or partners, making them easier to share than long URLs.

**Example Use Case**: An influencer promotes a subscription with the short code "JOIN12345" within their TikTok video's description. When users enter this code within your app during sign-up or before purchase, the app tracks the subscription back to the influencer for commission payouts.

For more information, visit the [Insert Affiliate Short Codes Documentation](https://docs.insertaffiliate.com/short-codes).

### Setting a Short Code

Use the `setShortCode` method to associate a short code with an affiliate. This is ideal for scenarios where users enter the code via an input field, pop-up, or similar UI element.

Short codes must meet the following criteria:
- Exactly **10 characters long**.
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

#### Example Usage
Set the Affiliate Identifier (required for tracking):

```swift
InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: "your_affiliate_link")
```

### 3. Offer Codes

Offer Codes enable you to automatically present an applied discount to users when they access an affiliate's link. This provides a compelling marketing incentive that affiliates can leverage in their outreach efforts. Detailed setup instructions and additional information are available [here.](https://docs.insertaffiliate.com/offer-codes)

To fetch an offer code and conditionally open the redeem URL:

```swift
InsertAffiliateSwift.fetchAndConditionallyOpenUrl(affiliateLink: "your_affiliate_link", offerCodeUrlId: "your_offer_code_url_id")
```