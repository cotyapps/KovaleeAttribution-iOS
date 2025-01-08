import AdSupport
import AppTrackingTransparency
import Foundation
import KovaleeSDK
import KovaleeFramework
import AdjustSdk
import StoreKit

extension AdjustConfiguration.Environment {
	var adjustEnvironment: String {
		switch self {
		case .production:
			return ADJEnvironmentProduction
		default:
			return ADJEnvironmentSandbox
		}
	}
}

extension AdjustConfiguration {
	public static var test: Self {
		Self.init(environment: "test", token: "")
	}
}

class AdjustWrapperImpl: NSObject, AttributionManager, Manager {
	init(
		configuration: AdjustConfiguration,
		attributionAdidCallback: @escaping (String?) -> Void
	) {
		KLogger.debug("initializing Adjust")
		
		self.attributionAdidCallback = attributionAdidCallback
		self.configuration = configuration
		super.init()
		
		let adjustConfig = ADJConfig(
			appToken: configuration.token,
			environment: configuration.environment.adjustEnvironment
		)
		adjustConfig?.logLevel = KLogger.logLevel.adjustLogLevel()
		adjustConfig?.attConsentWaitingInterval = 3
		adjustConfig?.delegate = self
		
		Adjust.initSdk(adjustConfig)
	}
	
	func setDataCollectionEnabled(_ enabled: Bool) {
		Adjust.trackThirdPartySharing(ADJThirdPartySharing(isEnabled: enabled ? 1 : 0)!)
	}
	
	func getAttributionAdid() async -> String? {
		await Adjust.adid()
	}
	
	func getSDKVersion() async -> String? {
		await Adjust.sdkVersion()
	}

	func promptTrackingAuthorization(completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void) {
		Adjust.requestAppTrackingAuthorization { _ in
			completion(ATTrackingManager.trackingAuthorizationStatus)
		}
	}

	func sendConversionValue(value: Int, coarseValue: String, completion: @escaping (Error?) -> Void) {
		if #available(iOS 16.1, *) {
			SKAdNetwork
				.updatePostbackConversionValue(
					value,
					coarseValue: SKAdNetwork.CoarseConversionValue(rawValue: coarseValue),
					lockWindow: false
				) { error in
					completion(error)
				}
		} else {
			// Fallback on earlier versions
			Adjust.updateSkanConversionValue(value, coarseValue: coarseValue, lockWindow: false) { error in
				completion(error)
			}
		}
	}
	
	var attributionAdidCallback: (String?) -> Void
	var configuration: AdjustConfiguration
}

extension AdjustWrapperImpl: AdjustDelegate {
	func adjustAttributionChanged(_ attribution: ADJAttribution?) {
		Task {
			let adid = await self.getAttributionAdid()
			self.attributionAdidCallback(adid)
		}
	}
	
	func adjustConversionValueUpdated(_ fineValue: NSNumber?, coarseValue: String?, lockWindow: NSNumber?) {
		KLogger.debug("Successfully Updated Conversion Value: \(String(describing: fineValue))")
	}
}

extension AttributionManager {
	static var test: AttributionManager {
		AdjustWrapperImpl(
			configuration: .test,
			attributionAdidCallback: { _ in }
		)
	}
}

extension LogLevel {
	func adjustLogLevel() -> ADJLogLevel {
		switch self {
		case .verbose:
				.verbose
		case .debug:
				.debug
		case .info:
				.info
		case .warn:
				.warn
		case .error:
				.error
		@unknown default:
			fatalError()
		}
	}
}
