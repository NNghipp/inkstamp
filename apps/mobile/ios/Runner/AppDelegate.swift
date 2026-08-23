import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let widgetChannelName = "com.inkstamp.app/widget"
  private let appGroup = "group.com.inkstamp.app"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "InkstampWidgetBridge"
      )
    else {
      return
    }

    let channel = FlutterMethodChannel(
      name: widgetChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "bridge_unavailable",
            message: "Widget bridge is unavailable.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "updateLatestStamp":
        guard
          let arguments = call.arguments as? [String: Any],
          let stampId = arguments["stampId"] as? String,
          let senderName = arguments["senderName"] as? String,
          let thumbnailPath = arguments["thumbnailPath"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Widget data is incomplete.",
              details: nil
            )
          )
          return
        }
        let defaults = UserDefaults(suiteName: self.appGroup)
        defaults?.set(stampId, forKey: "latest_stamp_id")
        defaults?.set(senderName, forKey: "latest_sender")
        defaults?.set(thumbnailPath, forKey: "latest_thumbnail_path")
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      case "clearWidget":
        let defaults = UserDefaults(suiteName: self.appGroup)
        defaults?.removeObject(forKey: "latest_stamp_id")
        defaults?.removeObject(forKey: "latest_sender")
        defaults?.removeObject(forKey: "latest_thumbnail_path")
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
