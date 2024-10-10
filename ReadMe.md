# InsertAffiliateSwift SDK for iOS

![Version](https://img.shields.io/badge/version-1.0.0-brightgreen) ![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)

## Overview

The **InsertAffiliateSwift SDK** is designed for iOS applications, providing seamless integration with the [Insert Affiliate platform](https://insertaffiliate.com). This SDK enables functionalities such as managing affiliate links, handling in-app purchases (IAP), and utilising deep links. For more details and to access the Insert Affiliate dashboard, visit [app.insertaffiliate.com](https://app.insertaffiliate.com).

### Features

- **Unique Device ID**: Generates and stores a short unique device ID to identify users.
- **Affiliate Identifier Management**: Set and retrieve the affiliate identifier based on user-specific links.
- **In-App Purchase (IAP) Initialisation**: Easily reinitialise in-app purchases with the option to validate using an affiliate identifier.
- **Offer Code Handling**: Fetch offer codes from the Insert Affiliate API and open redeem URLs directly in the App Store.

## Installation

To integrate the `InsertAffiliateSwift` SDK into your project, add the following dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/Insert-Affiliate/InsertAffiliateSwiftSDK.git", from: "1.0.0")
```

## Usage
### Import the SDK

Import the SDK in your Swift files:

```swift
import InsertAffiliateSwift
```

## Setting the Affiliate Identifier
You can set the affiliate identifier using the following method:

```swift
InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: "your_affiliate_link")
```

## Fetching Offer Codes

To fetch an offer code and conditionally open the redeem URL:

```swift
InsertAffiliateSwift.fetchAndConditionallyOpenUrl(affiliateLink: "your_affiliate_link", offerCodeUrlId: "your_offer_code_url_id")
```

## Reinitialising In-App Purchases

To reinitialise in-app purchases, use the following method:

- Replace `{{ your_iaptic_app_name }}` with your **Iaptic App Name**. You can find this [here](https://www.iaptic.com/account).
- Replace `{{ your_iaptic_secret_key }}` with your **Iaptic Secret Key**. You can find this [here](https://www.iaptic.com/settings).

```swift
let iapProducts: [IAPProduct] = [] // Your IAP products array
let validatorUrl = "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here}}",

InsertAffiliateSwift.reinitializeIAP(iapProductsArray: iapProducts, validatorUrlString: validatorUrl)
```

## In-App Purchase Setup
### Step 1: Add the In-App Purchase Platform Dependency

In this example, the deep linking functionality is implemented using Iaptic.

### Step 2: Modify Your `AppDelegate.swift` to Initialise In-App Purchases with Insert Affiliate:

- Replace `{{ your_iaptic_app_name }}` with your **Iaptic App Name**. You can find this [here](https://www.iaptic.com/account).
- Replace `{{ your_iaptic_secret_key }}` with your **Iaptic Secret Key**. You can find this [here](https://www.iaptic.com/settings).

Here's the example code with placeholders for you to swap out:

```swift
import SwiftUI
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    InsertAffiliateSwift.reinitializeIAP(
      iapProductsArray: [
        IAPProduct(
          productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
          productType: .autoRenewableSubscription
        )
      ],
      validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}"
    )
    return true
  }
}
```

## Deep Link Setup

### Step 1: Add the Deep Linking Platform Dependency

In this example, the deep linking functionality is implemented using Branch.io.

### Step 2: Modify Your Deep Link initSession function in `AppDelegate.swift`

After setting up your Branch integration, add the following code to initialise the Insert Affiliate SDK in your iOS app.

- Replace `{{ your_iaptic_app_name }}` with your **Iaptic App Name**. You can find this [here](https://www.iaptic.com/account).
- Replace `{{ your_iaptic_secret_key }}` with your **Iaptic Secret Key**. You can find this [here](https://www.iaptic.com/settings).

Here's the example code with placeholders for you to swap out:

```swift
import SwiftUI
import BranchSDK
import InAppPurchaseLib
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
      if let referringLink = params?["~referring_link"] as? String {
        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink)
        InsertAffiliateSwift.reinitializeIAP(
          iapProductsArray: [
            IAPProduct(
              productIdentifier: "{{ apple_in_app_purchase_subscription_id }}",
              productType: .autoRenewableSubscription
            )
          ],
          validatorUrlString: "https://validator.iaptic.com/v3/validate?appName={{ your_iaptic_app_name }}&apiKey={{ your_iaptic_app_key_goes_here }}",
          applicationUsername: uniqueAffiliateUsername
        )
      }
    }
    return true
  }
}
```