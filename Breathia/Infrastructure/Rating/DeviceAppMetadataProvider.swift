import Foundation
#if os(iOS)
import UIKit
#endif

/// Reads app and device details from the bundle, the system, and the kernel.
struct DeviceAppMetadataProvider: AppMetadataProviding {
    var metadata: AppMetadata {
        let info = Bundle.main.infoDictionary ?? [:]
        return AppMetadata(
            appName: info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? "Breathia",
            appVersion: info["CFBundleShortVersionString"] as? String ?? "–",
            buildNumber: info["CFBundleVersion"] as? String ?? "–",
            deviceModel: Self.modelIdentifier,
            systemName: Self.systemName,
            systemVersion: Self.systemVersion,
            localeIdentifier: Locale.current.identifier
        )
    }

    #if os(iOS)
    private static var systemName: String { UIDevice.current.systemName }
    private static var systemVersion: String { UIDevice.current.systemVersion }
    #else
    private static let systemName = "macOS"
    private static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    #endif

    /// The hardware identifier ("iPhone17,1", "Mac16,1") rather than the marketing
    /// name, which is what support needs. The Simulator reports the device it simulates.
    private static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        #if os(macOS)
        // On a Mac, `uname` only names the architecture; the model is in `hw.model`.
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(decoding: model.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        #endif
    }
}
