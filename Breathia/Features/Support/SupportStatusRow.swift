import SwiftUI

struct SupportStatusRow: View {
    let status: SupportStore.Status

    var body: some View {
        switch status {
        case .thankYou:
            Label("support.thankYou", systemImage: "heart.fill")
                .foregroundStyle(.pink)
        case .pending:
            Label("support.yourPurchaseIsWaiting", systemImage: "clock")
        case .restored:
            Label("support.purchasesRestored", systemImage: "checkmark.circle")
        case .nothingToRestore:
            Label("support.thereWereNoPurchases", systemImage: "info.circle")
        case let .failed(error):
            Label(error.message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }
}

private extension SupportStoreError {
    var message: LocalizedStringKey {
        switch self {
        case .storeUnavailable:
            "support.supportOptionsCouldnt"
        case .productUnavailable, .purchaseFailed:
            "support.thePurchaseCouldnt"
        case .verificationFailed:
            "support.thePurchaseCouldntBeVerified"
        case .restoreFailed:
            "support.purchasesCouldntBeRestored"
        }
    }
}
