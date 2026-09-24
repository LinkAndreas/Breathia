# Support the Developer — App Store Connect setup

Breathia's Support the Developer feature is **optional support**. It never unlocks
features; the app is fully usable for free. This document lists what has to be
configured in App Store Connect for the in-app code to work.

Product identifiers are defined once in `Breathia/Domain/Support/SupportProductID.swift`.
Names and prices are **not** in the code: the app shows the localized name and
price StoreKit returns, so both can be changed in App Store Connect at any time
without an app update.

## Prerequisites

1. **Agreements, Tax, and Banking** — the *Paid Apps* agreement must be active,
   otherwise StoreKit returns no products.
2. **In-App Purchase capability** — enabled on the `Breathia` app ID (Xcode ›
   Signing & Capabilities › + Capability › In-App Purchase). No entitlement key is
   needed.

## Products

### One-time support — type: Consumable

Consumables, so people can support more than once. They are not restorable, which
is expected for tips (Restore Purchases applies to subscriptions).

| Product ID                                 | Reference name   | Proposed price | Suggested display name |
|--------------------------------------------|------------------|----------------|------------------------|
| `de.linkandreas.breathia.support.small`    | Small Support    | €2.99          | ☕ Small Support        |
| `de.linkandreas.breathia.support.medium`   | Support          | €5.99          | ❤️ Support             |
| `de.linkandreas.breathia.support.generous` | Generous Support | €9.99          | ⭐ Generous Support     |

The app adds the emoji itself, so leave it out of the display name in App Store Connect.

### Recurring support — type: Auto-Renewable Subscription

Create one subscription group, **Support**, containing both subscriptions.

| Product ID                                | Reference name  | Duration | Proposed price | Group level |
|-------------------------------------------|-----------------|----------|----------------|-------------|
| `de.linkandreas.breathia.support.yearly`  | Yearly Support  | 1 year   | €14.99         | 1           |
| `de.linkandreas.breathia.support.monthly` | Monthly Support | 1 month  | €1.99          | 2           |

- No free trials or introductory offers — this is support, not access.
- Family Sharing: off.
- Localize the group display name, e.g. "Support Breathia".

### For every product

- **Localizations** — display name and description in English, German, Spanish,
  and French (the languages the app ships in). These are what the Support screen shows.
- **Price** — choose the price point in *Pricing*. The app uses
  `Product.displayPrice`, so the storefront's local currency is shown automatically.
- **Review screenshot** — a screenshot of the Support screen (Settings › About ›
  Support the Developer).
- **Review notes**, e.g.: "Optional developer support. Purchases and subscriptions
  unlock no content or features; the entire app is free. Found under Settings ›
  About › Support the Developer."

## App Review requirements covered by the app

- Localized price and billing period, taken from StoreKit, next to each option.
- A clear statement that subscriptions renew automatically, how to cancel, and
  that they unlock nothing (footer of the Recurring Support section).
- **Restore Purchases** button.
- Links to the **Terms of Use** and **Privacy Policy**, both published in German, English,
  Spanish and French at `https://www.linkandreas.de/breathia/termsofuse/<language>` and
  `…/privacy/<language>`. `SupportLinks` in `Breathia/Features/Support/SupportLinks.swift`
  opens the page in the app's language, and English for any other. Enter
  https://www.linkandreas.de/breathia/privacy/en in App Store Connect › App Privacy, and
  https://www.linkandreas.de/breathia/termsofuse/en as the custom license agreement (EULA)
  in App Store Connect › App Information.
- Manage Subscription opens the system subscription management sheet.

## Testing

### Local (Xcode, no App Store Connect needed)

`Config/Breathia.storekit` defines all five products.

1. Product › Scheme › Edit Scheme › Run › Options › **StoreKit Configuration** ›
   `Breathia.storekit`.
2. Run on a simulator or device. Use Debug › StoreKit › Manage Transactions to
   approve Ask to Buy purchases, refund, expire subscriptions, or simulate failures
   (Editor › Enable StoreKit Errors in the configuration file).

Things to check: loading, purchase, cancel, pending (Ask to Buy), failure,
subscription renewal, restore, offline launch ("Try Again").

### Sandbox

Create sandbox testers in App Store Connect › Users and Access › Sandbox, sign in
on a device under Settings › App Store › Sandbox Account, and run a build without
the StoreKit configuration file selected.

## Changing prices later

Change the price in App Store Connect › the product › Pricing. No code or app
update is needed; the next launch shows the new localized price. For subscriptions,
follow Apple's price-increase rules (existing subscribers may need to consent).
