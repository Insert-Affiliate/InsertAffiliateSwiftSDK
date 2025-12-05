# Branch.io Deep Linking Integration

This guide shows how to integrate InsertAffiliateSwift SDK with Branch.io for deep linking attribution.

## Prerequisites

- [Branch SDK for iOS](https://help.branch.io/developers-hub/docs/ios-basic-integration) installed and configured
- Create a Branch deep link and provide it to affiliates via the [Insert Affiliate dashboard](https://app.insertaffiliate.com/affiliates)

## Integration Examples

Choose the example that matches your IAP verification platform:

### Example with RevenueCat

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

### Example with Adapty

```swift
import SwiftUI
import BranchSDK
import Adapty
import InsertAffiliateSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
          if let referringLink = params?["~referring_link"] as? String {
            InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { result in
                guard let shortCode = result else {
                    return
                }

                Task {
                    do {
                        var builder = AdaptyProfileParameters.Builder()
                        builder = try builder.with(customAttribute: shortCode, forKey: "insert_affiliate")
                        try await Adapty.updateProfile(params: builder.build())
                    } catch {
                        print("Failed to set Adapty attribution: \(error.localizedDescription)")
                    }
                }
            }
          }
        }
        return true
    }
}
```

### Example with Apphud

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
        }
        return true
    }
}
```

### Example with Iaptic

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

**Replace the following:**
- `{{ your_iaptic_app_name }}` with your [Iaptic App Name](https://www.iaptic.com/account)
- `{{ your_iaptic_public_key }}` with your [Iaptic Public Key](https://www.iaptic.com/settings)

### Example with App Store Direct Integration

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

## Testing

Test your Branch deep link integration using:

```bash
# Test with your Branch link
xcrun simctl openurl booted "https://your-app.app.link/abc123"
```

## Troubleshooting

**Problem:** `~referring_link` is null
- **Solution:** Ensure Branch SDK is properly initialized before Insert Affiliate SDK
- Verify Branch link is properly configured with your app's URI scheme

**Problem:** Deep link opens browser instead of app
- **Solution:** Check Branch dashboard for associated domains configuration
- Verify your app's entitlements include the Branch link domain

## Next Steps

After completing Branch integration:
1. Test deep link attribution with a test affiliate link
2. Verify affiliate identifier is stored correctly
3. Make a test purchase to confirm tracking works end-to-end

[← Back to Main README](../README.md)
