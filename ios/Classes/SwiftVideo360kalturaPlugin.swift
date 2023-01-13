import Flutter
import UIKit

public class SwiftVrPlayer: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let factoryId: String = PlayerFlutterViewFactory.factoryIdentifier
    let factoryViewFactory: FlutterPlatformViewFactory = PlayerFlutterViewFactory(
      messenger: registrar.messenger()
    )
    registrar.register(factoryViewFactory, withId: factoryId)
  }

}
