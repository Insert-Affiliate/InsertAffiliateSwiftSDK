# Adapty Integration Guide

Complete guide for integrating Insert Affiliate with Adapty for in-app purchase verification and affiliate tracking.

## Overview

Adapty is a subscription management platform that provides paywall A/B testing, analytics, and subscription infrastructure. This guide shows how to integrate Insert Affiliate with Adapty to track affiliate-driven purchases.

## Prerequisites

- [Adapty account](https://adapty.io/) with configured products
- [Insert Affiliate account](https://app.insertaffiliate.com) with your company code
- Adapty SDK installed in your iOS app ([installation guide](https://docs.adapty.io/docs/ios-installation))
- InsertAffiliateSwift SDK installed

## Quick Start

### Step 1: Initialize Both SDKs

In your `AppDelegate.swift`:

```swift
import UIKit
import Adapty
import InsertAffiliateSwift

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Adapty
        Adapty.activate("YOUR_ADAPTY_PUBLIC_SDK_KEY")

        // Initialize Insert Affiliate
        InsertAffiliateSwift.initialize(
            companyCode: "YOUR_COMPANY_CODE",
            verboseLogging: true  // Disable in production
        )

        // Set existing affiliate identifier if available
        if let affiliateId = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
            Task {
                do {
                    var builder = AdaptyProfileParameters.Builder()
                    builder = try builder.with(customAttribute: affiliateId, forKey: "insert_affiliate")
                    try await Adapty.updateProfile(params: builder.build())
                    print("[Adapty] Set insert_affiliate attribute: \(affiliateId)")
                } catch {
                    print("[Adapty] Failed to set attribution: \(error.localizedDescription)")
                }
            }
        }

        return true
    }
}
```

### Step 2: Handle Deep Link Attribution

Update Adapty when a new affiliate identifier is set via deep link:

#### With Branch.io

```swift
import BranchSDK

// In AppDelegate
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // ... Adapty and InsertAffiliate initialization ...

    Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
        if let referringLink = params?["~referring_link"] as? String {
            InsertAffiliateSwift.setInsertAffiliateIdentifier(referringLink: referringLink) { result in
                guard let shortCode = result else {
                    print("[Insert Affiliate] Failed to set affiliate identifier")
                    return
                }

                // Update Adapty with new affiliate identifier
                Task {
                    do {
                        var builder = AdaptyProfileParameters.Builder()
                        builder = try builder.with(customAttribute: shortCode, forKey: "insert_affiliate")
                        try await Adapty.updateProfile(params: builder.build())
                        print("[Adapty] Updated insert_affiliate: \(shortCode)")
                    } catch {
                        print("[Adapty] Failed to update attribution: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    return true
}

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    Branch.getInstance().application(app, open: url, options: options)
    return true
}

func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    Branch.getInstance().continue(userActivity)
    return true
}
```

#### With Insert Links

```swift
import InsertAffiliateSwift

// In AppDelegate
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // Initialize with Insert Links enabled
    InsertAffiliateSwift.initialize(
        companyCode: "YOUR_COMPANY_CODE",
        verboseLogging: true,
        insertLinksEnabled: true
    )

    // Set up callback for affiliate identifier changes
    InsertAffiliateSwift.setInsertAffiliateIdentifierChangeCallback { identifier in
        if let identifier = identifier {
            Task {
                do {
                    var builder = AdaptyProfileParameters.Builder()
                    builder = try builder.with(customAttribute: identifier, forKey: "insert_affiliate")
                    try await Adapty.updateProfile(params: builder.build())
                    print("[Adapty] Updated insert_affiliate: \(identifier)")
                } catch {
                    print("[Adapty] Failed to update attribution: \(error.localizedDescription)")
                }
            }
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
```

### Step 3: Configure Webhooks

1. **In Insert Affiliate Dashboard** ([app.insertaffiliate.com/settings](https://app.insertaffiliate.com/settings)):
   - Set **In-App Purchase Verification** to `Adapty`
   - Copy the `Adapty Webhook URL` (you'll need this for both production and sandbox)
   - Copy the `Adapty Webhook Authorization Header` value

2. **In Adapty Dashboard** ([app.adapty.io/integrations](https://app.adapty.io/integrations)):
   - Navigate to **Integrations** → **Webhooks**
   - Set **Production URL** to the webhook URL copied from Insert Affiliate
   - Set **Sandbox URL** to the same webhook URL
   - Paste the `Adapty Webhook Authorization Header` value into the **Authorization header value** field
   - Enable these options:
     - **Exclude historical events**
     - **Send attribution**
     - **Send trial price**
     - **Send user attributes**
   - Save the webhook configuration

## Complete ViewModel Example

Here's a complete example of an Adapty-based ViewModel with Insert Affiliate integration:

```swift
import Adapty
import StoreKit
import SwiftUI
import InsertAffiliateSwift

class InAppPurchaseViewModelAdapty: NSObject, ObservableObject {
    @Published var products: [String: AdaptyPaywallProduct] = [:]
    @Published var paywall: AdaptyPaywall?
    @Published var isPurchasing: Bool = false

    static let shared = InAppPurchaseViewModelAdapty()

    let baseProductIdentifier = "oneMonthSubscription"
    let paywallPlacementId = "default"  // Configure in Adapty dashboard

    // Dynamic product identifier with offer code support
    var dynamicProductIdentifier: String {
        if let offerCode = InsertAffiliateSwift.OfferCode, !offerCode.isEmpty {
            let cleanOfferCode = offerCode.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return "\(baseProductIdentifier)\(cleanOfferCode)"
        }
        return baseProductIdentifier
    }

    override init() {
        super.init()
    }

    func loadProducts() {
        Task {
            do {
                let paywall = try await Adapty.getPaywall(placementId: paywallPlacementId)
                let products = try await Adapty.getPaywallProducts(paywall: paywall)

                await MainActor.run {
                    self.paywall = paywall
                    for product in products {
                        self.products[product.vendorProductId] = product
                        print("[Adapty] Loaded product: \(product.vendorProductId)")
                    }
                }
            } catch {
                print("[Adapty] Failed to load products: \(error.localizedDescription)")
            }
        }
    }

    func purchase(productIdentifier: String) {
        guard let product = products[productIdentifier] else {
            print("[Adapty] Product not found: \(productIdentifier)")
            return
        }

        Task {
            await MainActor.run { isPurchasing = true }

            do {
                let profile = try await Adapty.makePurchase(product: product)
                print("[Adapty] Purchase successful")
                print("[Adapty] Profile: \(profile)")
            } catch let error as AdaptyError {
                if error.adaptyErrorCode == .paymentCancelled {
                    print("[Adapty] Purchase cancelled by user")
                } else {
                    print("[Adapty] Purchase failed: \(error.localizedDescription)")
                }
            } catch {
                print("[Adapty] Purchase failed: \(error.localizedDescription)")
            }

            await MainActor.run { isPurchasing = false }
        }
    }

    func restorePurchases() {
        Task {
            do {
                let profile = try await Adapty.restorePurchases()
                print("[Adapty] Restore successful: \(profile)")
            } catch {
                print("[Adapty] Restore failed: \(error.localizedDescription)")
            }
        }
    }

    func hasActiveSubscription(accessLevel: String = "premium") async -> Bool {
        do {
            let profile = try await Adapty.getProfile()
            return profile.accessLevels[accessLevel]?.isActive ?? false
        } catch {
            print("[Adapty] Failed to check subscription: \(error.localizedDescription)")
            return false
        }
    }
}
```

## Complete View Example

```swift
import SwiftUI
import Adapty
import InsertAffiliateSwift

struct UpgradeViewAdapty: View {
    @EnvironmentObject var viewModel: InAppPurchaseViewModelAdapty
    @State private var shortCodeInput: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Upgrade to Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Product display
                if let product = viewModel.products[viewModel.dynamicProductIdentifier] {
                    VStack(spacing: 15) {
                        Text(product.localizedTitle)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(product.localizedDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)

                        Text("Price: \(product.localizedPrice ?? "")")
                            .font(.headline)

                        // Short code input for manual affiliate entry
                        VStack(spacing: 10) {
                            Text("Have a promo code?")
                                .font(.subheadline)

                            TextField("Enter code", text: $shortCodeInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)

                            Button("Apply Code") {
                                Task {
                                    let isValid = await InsertAffiliateSwift.setShortCode(shortCode: shortCodeInput)
                                    if isValid {
                                        alertMessage = "Code applied successfully!"
                                        // Refresh products to get offer code product
                                        viewModel.loadProducts()
                                    } else {
                                        alertMessage = "Invalid code. Please try again."
                                    }
                                    showAlert = true
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                        // Purchase button
                        Button(action: {
                            viewModel.purchase(productIdentifier: product.vendorProductId)
                        }) {
                            if viewModel.isPurchasing {
                                ProgressView()
                            } else {
                                Text("Subscribe Now")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(viewModel.isPurchasing)

                        // Restore purchases
                        Button("Restore Purchases") {
                            viewModel.restorePurchases()
                        }
                        .font(.footnote)
                    }
                    .padding()
                } else {
                    ProgressView("Loading products...")
                        .onAppear {
                            viewModel.loadProducts()
                        }
                }
            }
            .padding()
        }
        .alert("Promo Code", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }
}
```

## Dynamic Offer Codes with Adapty

Automatically apply discounts when users come from specific affiliates by showing them a different paywall.

### How It Works

1. Create two paywalls in Adapty - one with your base product, one with the promotional product (e.g., with free trial)
2. Create two placements - one for default users, one for affiliate users with offers
3. In your app, select the correct placement based on whether the user has an offer code

This approach lets you use Adapty's paywall builder and A/B testing for both variants.

### Setup

1. **App Store Connect**: Create your base subscription and a variant with an introductory offer (e.g., 1 week free trial)

2. **Adapty Dashboard**:
   - Create two paywalls:
     - Default paywall with your base product
     - Promotional paywall with your offer product
   - Create two placements:
     - `default` → linked to default paywall
     - `affiliate_offer` → linked to promotional paywall

3. **Insert Affiliate Dashboard**: Configure the offer code modifier (e.g., `_oneWeekFree`) for specific affiliates

### Implementation

```swift
// In your ViewModel
let defaultPlacementId = "default"
let affiliateOfferPlacementId = "affiliate_offer"

// Select placement based on whether user has an offer code
var activePlacementId: String {
    if let offerCode = InsertAffiliateSwift.OfferCode, !offerCode.isEmpty {
        return affiliateOfferPlacementId
    }
    return defaultPlacementId
}

func loadProducts() {
    Task {
        do {
            // Load the appropriate paywall based on offer code
            let paywall = try await Adapty.getPaywall(placementId: activePlacementId)
            let products = try await Adapty.getPaywallProducts(paywall: paywall)

            await MainActor.run {
                self.paywall = paywall
                for product in products {
                    self.products[product.vendorProductId] = product
                }
                print("Loaded paywall: \(self.activePlacementId)")
            }
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
        }
    }
}
```

This ensures:
- Users from affiliates with offer codes see the promotional paywall (with free trial messaging, different design, etc.)
- Regular users see the default paywall
- You can use Adapty's full paywall builder features for both

See [Dynamic Offer Codes Guide](dynamic-offer-codes.md) for complete details on App Store Connect setup and configuration.

## Adapty Dashboard Configuration

### Creating a Paywall

1. Go to [app.adapty.io](https://app.adapty.io/) → **Paywalls**
2. Click **Create paywall**
3. Add your subscription products
4. Configure paywall design and copy

### Creating a Placement

1. Go to **Placements**
2. Click **Create placement**
3. Give it an ID (e.g., `default`)
4. Link your paywall to the placement
5. Use this placement ID in your code

### Setting Up Webhooks

1. Go to **Integrations** → **Webhooks**
2. Click **Add webhook**
3. Enter the Insert Affiliate webhook URL
4. Select event types:
   - `subscription_started`
   - `subscription_renewed`
   - `trial_started`
   - `trial_converted`
5. Save configuration

## Testing

### Test Deep Link Attribution

```bash
# Test with Branch link
xcrun simctl openurl booted "https://your-app.app.link/test-affiliate"

# Test with Insert Links
xcrun simctl openurl booted "YOUR_IOS_URL_SCHEME://TEST_SHORT_CODE"
```

### Verify Affiliate Identifier

```swift
// Check stored affiliate identifier
if let affiliateId = InsertAffiliateSwift.returnInsertAffiliateIdentifier() {
    print("Affiliate ID: \(affiliateId)")
}

// Check offer code
if let offerCode = InsertAffiliateSwift.OfferCode {
    print("Offer Code: \(offerCode)")
}
```

### Test Purchase Flow

1. Click an affiliate test link
2. Verify affiliate identifier is set
3. Open paywall and verify correct product is shown
4. Complete a sandbox purchase
5. Check Insert Affiliate dashboard for the tracked purchase

## Troubleshooting

### Verifying Attribution in Adapty Dashboard

To confirm the affiliate identifier is being set correctly:

1. Go to [app.adapty.io/profiles/users](https://app.adapty.io/profiles/users)
2. Find and select the user who made a test purchase
3. Look for the **Custom attributes** section
4. Verify the `insert_affiliate` attribute exists with the format: `{SHORT_CODE}-{UUID}`
   - Example: `SAVE20-a1b2c3d4-e5f6-7890-abcd-ef1234567890`

If the attribute is missing or incorrect, check the solutions below.

### Affiliate Identifier Not Set in Adapty

**Problem:** Purchases not attributed to affiliate in Insert Affiliate dashboard

**Solutions:**
- Verify `insert_affiliate` custom attribute is set before purchase (check Adapty dashboard as described above)
- Ensure `Adapty.updateProfile` is called after setting affiliate identifier
- Check that webhook is configured correctly in Adapty

### Products Not Loading

**Problem:** `getPaywallProducts` returns empty array

**Solutions:**
- Verify placement ID matches your Adapty dashboard configuration
- Check that products are added to the paywall
- Ensure products are configured in App Store Connect
- Verify Adapty API key is correct

### Dynamic Product Not Found

**Problem:** Offer code product not available

**Solutions:**
- Verify promotional product exists in App Store Connect
- Check product is added to Adapty paywall
- Ensure offer code modifier matches product ID suffix exactly
- Confirm offer code is set before loading products

### Webhook Not Receiving Events

**Problem:** Insert Affiliate not receiving purchase notifications

**Solutions:**
- Verify webhook URL is correctly entered in Adapty
- Check webhook is enabled and active
- Verify event types are selected
- Test webhook using Adapty's webhook testing feature

## Best Practices

1. **Initialize Early**: Call `Adapty.activate()` and `InsertAffiliateSwift.initialize()` in `application(_:didFinishLaunchingWithOptions:)`

2. **Handle Errors Gracefully**: Always handle Adapty errors, especially `paymentCancelled`

3. **Update Attribution on Deep Link**: Always update Adapty custom attribute when affiliate identifier changes

4. **Use Placements**: Organize paywalls with placements for A/B testing flexibility

5. **Test Thoroughly**: Test complete flow from deep link to purchase in sandbox environment

## Next Steps

- Configure affiliate offer codes in [Insert Affiliate dashboard](https://app.insertaffiliate.com/affiliates)
- Set up A/B tests for paywalls in [Adapty dashboard](https://app.adapty.io/)
- Review [Dynamic Offer Codes guide](dynamic-offer-codes.md) for promotional offers
- Check [Deep Linking guides](deep-linking-branch.md) for attribution setup

[← Back to Main README](../ReadMe.md)
