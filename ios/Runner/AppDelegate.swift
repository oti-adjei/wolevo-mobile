import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Alternate app icons.
  ///
  /// Implemented here rather than with a plugin: every dynamic-icon package on
  /// pub is CocoaPods-only, and this project builds with Swift Package Manager.
  /// The whole feature is `setAlternateIconName`, so a channel in the app
  /// target is less machinery than adding CocoaPods to the toolchain.
  private static let iconChannelName = "wolevo/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerIconChannel(with: engineBridge.pluginRegistry)
  }

  private func registerIconChannel(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "WolevoAppIcon")?.messenger() else {
      return
    }

    let channel = FlutterMethodChannel(
      name: AppDelegate.iconChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "supportsAlternateIcons":
        result(UIApplication.shared.supportsAlternateIcons)

      case "setAlternateIcon":
        // nil restores the primary icon.
        let name = (call.arguments as? [String: Any])?["name"] as? String
        UIApplication.shared.setAlternateIconName(name) { error in
          if let error = error {
            result(
              FlutterError(
                code: "icon_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }

      case "currentIcon":
        result(UIApplication.shared.alternateIconName)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
