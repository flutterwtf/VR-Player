import Flutter
import PlayKit
import PlayKitProviders

final class PlayerFlutterViewFactory: NSObject, FlutterPlatformViewFactory {
    
    static let factoryIdentifier: String = "plugins.vr_player/player_view"
    
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        
        let playerFlutterView = PlayerFlutterView(
            frame: frame,
            viewId: viewId,
            arguments: args as? [String : Any],
            messenger: messenger
        )
        
        return playerFlutterView
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
}

final class PlayerFlutterView: NSObject, FlutterPlatformView {
    
    private let viewId: Int64
    
    private let args: Dictionary<String, Any>?
    
    private let player: Player = PlayKitManager.shared.loadPlayer(pluginConfig: nil)
    private let flutterView: PlayerView
    
    private let channel: FlutterMethodChannel
    private let flutterChannels: [KalturaFlutterEventChannel]
    
    init(frame: CGRect, viewId: Int64, arguments: [String: Any]?, messenger: FlutterBinaryMessenger) {
        self.viewId = viewId;
        self.args = arguments
        
        self.channel = FlutterMethodChannel(
            name: String(format: "vr_player_%lld", viewId),
            binaryMessenger: messenger
        )
        
        flutterChannels = [
            KalturaStateEventChannel(
                name: String(format: "vr_player_events_%lld_state", viewId),
                binaryMessenger: messenger,
                player: player,
                playerEvents: [PlayerEvent.stateChanged]
            ),
            KalturaDurationEventChannel(
                name: String(format: "vr_player_events_%lld_duration", viewId),
                binaryMessenger: messenger,
                player: player,
                playerEvents: [PlayerEvent.durationChanged]
            ),
            KalturaPositionEventChannel(
                name: String(format: "vr_player_events_%lld_position", viewId),
                binaryMessenger: messenger,
                player: player,
                playerEvents: PlayerEvent.allEventTypes
            ),
            KalturaEndedEventChannel(
                name: String(format: "vr_player_events_%lld_ended", viewId),
                binaryMessenger: messenger,
                player: player,
                playerEvents: [PlayerEvent.ended]
            )
        ]
        
        let viewFrame = CGRect(
            x: CGFloat(args?["x"] as? Double ?? 0.0),
            y: CGFloat(args?["y"] as? Double ?? 0.0),
            width: CGFloat(args?["width"] as? Double ?? 0.0),
            height: CGFloat(args?["height"] as? Double ?? 0.0)
        )
        
        flutterView = PlayerView(frame: viewFrame)
        player.view = flutterView
        
        super.init()
        
        self.channel.setMethodCallHandler(methodCallback)
    }
    
    func view() -> UIView {
        return flutterView
    }

    func methodCallback(call: FlutterMethodCall, result: FlutterResult)  {
        
        switch call.method {
        case "loadVideo":
            loadVideo(arguments: call.arguments as? [String: Any], result: result)
        case "onOrientationChanged":
            onOrientationChanged(arguments: call.arguments, result: result)
        case "onSizeChanged":
            onSizeChanged(arguments: call.arguments, result: result)
        case "isPlaying":
            isPlaying(arguments: call.arguments, result: result)
        case "setVolume" :
            setVolume(arguments: call.arguments, result: result)
        case "play":
            play(arguments: call.arguments, result: result)
        case "pause":
            pause(arguments: call.arguments, result: result)
        case "toggleVRMode":
            toggleVRMode(arguments: call.arguments, result: result)
        case "seekTo":
            seekTo(arguments: call.arguments, result: result)
        case "onPause":
            onPause(arguments: call.arguments, result: result)
        case "onResume":
            onResume(arguments: call.arguments, result: result)
        default:
            methodCall(arguments: call.arguments, result: result)
        }
    }
    
    private func methodCall(arguments: Any?, result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
    
    private func loadVideo(arguments: [String: Any]?, result: FlutterResult) {
        
        PlayKitManager.logLevel = .info
        
        let contentURL = arguments?["videoUrl"] as? String
        let contentPath = arguments?["videoPath"] as? String
        
        // create media source and initialize a media entry with that source
        let entryId = "entry"
        
        if (contentPath != nil) {
            let simpleStorage = DefaultLocalDataStore.defaultDataStore()
            lazy var assetsManager: LocalAssetsManager = { return LocalAssetsManager.manager(storage: simpleStorage!)}()
            
            // setup local media entry
            let localEntry = assetsManager.createLocalMediaEntry(for: entryId, localURL: NSURL.fileURL(withPath: contentPath!))
            localEntry.tags = "360"
            
            let mediaConfig = MediaConfig(mediaEntry: localEntry)
            
            self.player.prepare(mediaConfig)
        } else {
            let source = PKMediaSource(entryId, contentUrl: URL(string: contentURL!), drmData: nil, mediaFormat: .hls)
            
            // setup media entry
            let mediaEntry = PKMediaEntry(entryId, sources: [source], duration: -1)
            mediaEntry.tags = "360"
            
            // create media config
            let mediaConfig = MediaConfig(mediaEntry: mediaEntry)
            
            self.player.prepare(mediaConfig)
        }
        
        result(nil)
    }
    
    private func onOrientationChanged(arguments: Any?, result: FlutterResult) {
        result(nil)
    }
    
    private func onSizeChanged(arguments: Any?, result: FlutterResult) {
        result(nil)
    }
    
    private func isPlaying(arguments: Any?, result: FlutterResult) {
        result(nil)
    }
    
    private func play(arguments: Any?, result: FlutterResult) {
        player.play()
        result(nil)
    }
    
    private func pause(arguments: Any?, result: FlutterResult) {
        player.pause()
        result(nil)
    }

    private func setVolume(arguments: [Double: Any], result: FlutterResult) {
        let volume = arguments["volume"] as? Double
        player.setVolume(arguments["volume"] )
        result(nil)
    }
    
    private func toggleVRMode(arguments: Any?, result: FlutterResult) {
        guard let vrController = self.player.getController(ofType: PKVRController.self) else {
            return
        }
        vrController.setVRModeEnabled(true)
        self.player.view?.sizeToFit()
        
        result(nil)
    }
    
    private func seekTo(arguments: Any?, result: FlutterResult) {
        
        guard let arguments = arguments as? [String: Any] else {
            result(nil)
            return
        }
        
        let seekTimeInterval: TimeInterval
        if let timePosition = arguments["position"] as? TimeInterval {
            seekTimeInterval = timePosition / 1_000.0
        } else {
            seekTimeInterval = 0.0
        }
        
        player.seek(to: seekTimeInterval)
        
        result(nil)
    }
    
    private func onPause(arguments: Any?, result: FlutterResult) {
        result(nil)
    }
    
    private func onResume(arguments: Any?, result: FlutterResult) {
        result(nil)
    }
    
}

class KalturaFlutterEventChannel: NSObject, FlutterStreamHandler {
    
    internal let playerEngine: Player
    private let playerEvents: [PKEvent.Type]
    
    let eventChannelName: String
    private let eventChannel: FlutterEventChannel
    private(set) var eventSink: FlutterEventSink?
    
    init(
        name: String,
        binaryMessenger messenger: FlutterBinaryMessenger,
        player: Player,
        playerEvents: [PKEvent.Type] = []
    ) {
        
        self.playerEngine = player
        self.playerEvents = playerEvents
        self.eventChannelName = name
        self.eventChannel = FlutterEventChannel(name: name, binaryMessenger: messenger)
        
        super.init()
        
        eventChannel.setStreamHandler(self)
        
        playerEngine.addObserver(self, events: playerEvents, block: playerEventListener)
    }
    
    func playerEventListener(playerEvent: PKEvent) { }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if let arguments = arguments {
            print(arguments)
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        playerEngine.removeObserver(self, events: playerEvents)
        if let arguments = arguments {
            print(arguments)
        }
        return nil
    }
    
}

class KalturaStateEventChannel: KalturaFlutterEventChannel {
    
    override func playerEventListener(playerEvent: PKEvent) {
        
        let state: Int
        switch playerEngine.currentState {
        case .idle:
            state = 0
        case .ready:
            state = 1
        default:
            state = 2
        }
        
        let eventResponse = [
            "state": state
        ]
        
        eventSink?(eventResponse)
    }
    
}

class KalturaDurationEventChannel: KalturaFlutterEventChannel {
    
    override func playerEventListener(playerEvent: PKEvent) {
        
        let eventResponse = [
            "duration": NSNumber(value: 1000.0 * playerEngine.duration).intValue,
        ]
        
        eventSink?(eventResponse)
    }
    
}

class KalturaPositionEventChannel: KalturaFlutterEventChannel {
    
    override func playerEventListener(playerEvent: PKEvent) {
        
        let eventResponse = [
            "currentPosition": NSNumber(value: 1000.0 * playerEngine.currentTime).intValue,
        ]
        
        eventSink?(eventResponse)
    }
    
}

class KalturaEndedEventChannel: KalturaFlutterEventChannel {
    
    override func playerEventListener(playerEvent: PKEvent) {
        
        let eventResponse = [
            "ended": playerEngine.currentState == PlayerState.ended,
        ]
        
        eventSink?(eventResponse)
    }
    
}
