import Flutter
import UIKit
import TikTokBusinessSDK

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // ===== TikTok Business SDK config =====
  // Values from TikTok Events Manager. `appId` = "ID Ứng dụng",
  // `tiktokAppId` = "ID ứng dụng TikTok". `accessToken` is optional (used for
  // Enhanced Data Postback); leave empty until a token is issued.
  private let ttAppId = "6760386944"
  private let ttTikTokAppId = "7653820676664147975"
  private let ttAccessToken = ""

  private var tiktokChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    initTikTokSDK()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerTikTokChannel(engineBridge.pluginRegistry)
  }

  // App Tracking Transparency prompt must be shown while the app is active.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    TikTokBusiness.requestTrackingAuthorization { _ in }
  }

  // MARK: - TikTok setup

  private func initTikTokSDK() {
    let config: TikTokConfig?
    if ttAccessToken.isEmpty {
      // Client-only event tracking (no Enhanced Data Postback token yet).
      config = TikTokConfig(appId: ttAppId, tiktokAppId: ttTikTokAppId)
    } else {
      config = TikTokConfig(accessToken: ttAccessToken, appId: ttAppId, tiktokAppId: ttTikTokAppId)
    }
    #if DEBUG
    config?.enableDebugMode()
    #endif
    TikTokBusiness.initializeSdk(config)
  }

  private func registerTikTokChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "RunlyTikTokPlugin") else { return }
    let channel = FlutterMethodChannel(
      name: "com.runly.app/tiktok",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleTikTokCall(call, result)
    }
    tiktokChannel = channel
  }

  private func handleTikTokCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "trackEvent":
      guard let name = args?["eventName"] as? String else {
        result(FlutterError(code: "bad_args", message: "eventName required", details: nil))
        return
      }
      let event: TikTokBaseEvent
      if let eventId = args?["eventId"] as? String {
        event = TikTokBaseEvent(eventName: name, eventId: eventId)
      } else {
        event = TikTokBaseEvent(eventName: name)
      }
      if let props = args?["properties"] as? [String: Any] {
        for (key, value) in props {
          _ = event.addProperty(withKey: key, value: value)
        }
      }
      TikTokBusiness.trackTTEvent(event)
      result(nil)

    case "identify":
      TikTokBusiness.identify(
        withExternalID: args?["externalId"] as? String,
        externalUserName: args?["userName"] as? String,
        phoneNumber: args?["phone"] as? String,
        email: args?["email"] as? String
      )
      result(nil)

    case "logout":
      TikTokBusiness.logout()
      result(nil)

    case "requestTracking":
      TikTokBusiness.requestTrackingAuthorization { _ in }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
