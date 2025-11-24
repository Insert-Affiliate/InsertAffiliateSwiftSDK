# Dynamic Offer Codes Complete Guide

Automatically apply discounts or trials when users come from specific affiliates using offer code modifiers.

## How It Works

When someone clicks an affiliate link or enters a short code linked to an offer (set up in the Insert Affiliate Dashboard), the SDK fills in `InsertAffiliateSwift.OfferCode` with the right modifier (like `_oneWeekFree`). You can then add this to your regular product ID to load the correct version of the subscription in your app.

## Setup in Insert Affiliate Dashboard

1. Go to [app.insertaffiliate.com/affiliates](https://app.insertaffiliate.com/affiliates)
2. Select the affiliate you want to configure
3. Click "View" to access the affiliate's settings
4. Assign an **iOS IAP Modifier** to the affiliate (e.g., `_oneWeekFree`, `_threeMonthsFree`)
5. Save the settings

Once configured, when users click that affiliate's links or enter their short codes, your app will automatically receive the modifier and can load the appropriate discounted product.

## Setup in App Store Connect

Make sure you have created the corresponding subscription products in App Store Connect:
- Your base subscription (e.g., `oneMonthSubscriptionTwo`)
- Promotional offer variants (e.g., `oneMonthSubscriptionTwo_oneWeekFree`)

Both must be configured and published to at least TestFlight for testing.

## Implementation Examples

### RevenueCat Example

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

### Native StoreKit 2 Example

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

### Purchase View Integration

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

## Example Product Identifiers

- Base product: `oneMonthSubscriptionTwo`
- With introductory discount: `oneMonthSubscriptionTwo_oneWeekFree`
- With different offer: `oneMonthSubscriptionTwo_threeMonthsFree`

## Best Practices

1. **Call in Purchase Views**: Always implement this logic in views where users can make purchases
2. **Handle Both Cases**: Ensure your app works whether an offer code is present or not
3. **Fallback**: Have a fallback to your base product if the dynamic product isn't found
4. **Clean the modifier**: Always trim quotes and whitespace from the offer code

## Testing

1. **Set up test affiliate** with offer code modifier in Insert Affiliate dashboard
2. **Click test affiliate link** or enter short code
3. **Verify offer code** is stored:
   ```swift
   if let offerCode = InsertAffiliateSwift.OfferCode {
       print("Offer code: \(offerCode)")
   }
   ```
4. **Check dynamic product ID** is constructed correctly
5. **Complete test purchase** to verify correct product is purchased

## Troubleshooting

**Problem:** Offer code is nil
- **Solution:** Ensure affiliate has offer code modifier configured in dashboard
- Verify user clicked affiliate link or entered short code before checking

**Problem:** Promotional product not found in App Store
- **Solution:** Verify promotional product exists in App Store Connect
- Check product ID matches exactly (including the modifier)
- Ensure product is published to at least TestFlight

**Problem:** Always showing base product instead of promotional
- **Solution:** Ensure offer code is retrieved before fetching products
- Check that `InsertAffiliateSwift.OfferCode` is not nil
- Verify the dynamic product identifier is correct

**Problem:** Purchase tracking not working with promotional product
- **Solution:** Ensure you're using `returnUserAccountTokenAndStoreExpectedTransaction()` for App Store Direct
- For RevenueCat/Apphud/Iaptic, verify `insert_affiliate` attribute is set correctly

## Next Steps

- Configure offer code modifiers for high-value affiliates
- Create promotional products in App Store Connect
- Test the complete flow from link click to purchase
- Monitor affiliate performance in Insert Affiliate dashboard

[← Back to Main README](../README.md)
