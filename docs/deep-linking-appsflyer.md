# AppsFlyer Deep Linking Integration

This guide shows how to integrate InsertAffiliateSwift SDK with AppsFlyer for deep linking attribution.

## Prerequisites

- [AppsFlyer SDK for iOS](https://dev.appsflyer.com/hc/docs/ios-sdk-reference-getting-started) installed and configured
- Create an AppsFlyer OneLink and provide it to affiliates via the [Insert Affiliate dashboard](https://app.insertaffiliate.com/affiliates)

## Platform Setup

Complete the deep linking setup for AppsFlyer by following their official documentation:
- [AppsFlyer Deferred Deep Link Integration Guide](https://dev.appsflyer.com/hc/docs/deeplinkintegrate)

This covers:
- Info.plist configuration
- AppDelegate setup
- Universal links configuration
- Testing and troubleshooting

## Integration Examples

Choose the example that matches your IAP verification platform:

### Example with RevenueCat

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

    /// First install (deferred) fallback via conversion data
    func onConversionDataSuccess(_ installData: [AnyHashable : Any]) {
        let data = installData as? [String: Any] ?? [:]
        let isFirst = (data["is_first_launch"] as? Bool) ?? false
        if isFirst { handleAppsFlyerDeepLink(installData) }
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

### Example with Adapty

```swift
import SwiftUI
import AppsFlyerLib
import Adapty
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

    /// First install (deferred) fallback via conversion data
    func onConversionDataSuccess(_ installData: [AnyHashable : Any]) {
        let data = installData as? [String: Any] ?? [:]
        let isFirst = (data["is_first_launch"] as? Bool) ?? false
        if isFirst { handleAppsFlyerDeepLink(installData) }
    }

    private func handleAppsFlyerDeepLink(_ attributionData: [AnyHashable: Any]) {
        let dict = attributionData as? [String: Any] ?? [:]
        let referringLink = (dict["link"] as? String) ?? (dict["deep_link_value"] as? String) ?? (dict["af_dp"] as? String)

        guard let link = referringLink else { return }

        InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: link) { shortCode in
            guard let shortCode = shortCode else { return }

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
```

### Example with Iaptic

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

    /// First install (deferred) fallback via conversion data
    func onConversionDataSuccess(_ installData: [AnyHashable : Any]) {
        let data = installData as? [String: Any] ?? [:]
        let isFirst = (data["is_first_launch"] as? Bool) ?? false
        if isFirst { handleAppsFlyerDeepLink(installData) }
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

**Replace the following:**
- `{{ your_iaptic_app_name }}` with your [Iaptic App Name](https://www.iaptic.com/account)
- `{{ your_iaptic_public_key }}` with your [Iaptic Public Key](https://www.iaptic.com/settings)

### Example with App Store Direct Integration

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

    /// First install (deferred) fallback via conversion data
    func onConversionDataSuccess(_ installData: [AnyHashable : Any]) {
        let data = installData as? [String: Any] ?? [:]
        let isFirst = (data["is_first_launch"] as? Bool) ?? false
        if isFirst { handleAppsFlyerDeepLink(installData) }
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

## Testing

Test your AppsFlyer deep link integration:

```bash
# Test with your OneLink URL
xcrun simctl openurl booted "https://your-app.onelink.me/abc123"
```

## Troubleshooting

**Problem:** Attribution callback not firing
- **Solution:** Ensure AppsFlyer SDK is initialized with correct dev key and app ID
- Check AppsFlyer dashboard to verify OneLink is active

**Problem:** Deep link parameters not captured
- **Solution:** Verify deep link contains correct parameters in AppsFlyer dashboard
- Check Info.plist has correct URL schemes and associated domains

**Problem:** Deferred deep linking not working
- **Solution:** Make sure `onConversionDataSuccess` is implemented
- Test with a fresh app install (uninstall/reinstall)

## Next Steps

After completing AppsFlyer integration:
1. Test deep link attribution with a test affiliate link
2. Verify affiliate identifier is stored correctly
3. Make a test purchase to confirm tracking works end-to-end

[← Back to Main README](../README.md)
