# InsertAffiliateSwift SDK for iOS

![Version](https://img.shields.io/badge/version-1.0.0-brightgreen) ![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)

## Overview

`InsertAffiliateSwift` is a Swift SDK designed for iOS applications that integrate with the Insert Affiliate platform. This SDK provides functionalities to handle affiliate links, fetch offer codes, and open redeem URLs seamlessly within your app.

### Features

- **Unique Device ID**: Generates and stores a short unique device ID to identify users.
- **Affiliate Identifier Management**: Set and retrieve the affiliate identifier based on user-specific links.
- **In-App Purchase (IAP) Initialization**: Easily reinitialize in-app purchases with the option to validate using an affiliate identifier.
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

## Reinitializing In-App Purchases
If you need to reinitialize in-app purchases, use the following method:

```swift
let iapProducts: [IAPProduct] = [] // Your IAP products array
let validatorUrl = "https://your-validator-url.com"

InsertAffiliateSwift.reinitializeIAP(iapProductsArray: iapProducts, validatorUrlString: validatorUrl)
```

## Contribution
Contributions are welcome! If you have suggestions for improvements or new features, please fork the repository and submit a pull request.
