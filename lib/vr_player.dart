import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class VrPlayerController {
  late MethodChannel _channel;

  VrPlayerController.init(int id) {
    _channel = MethodChannel('vr_player_$id');
  }

  /// Initializes video based on configuration.
  /// Invoke actions which need to be run on player start.
  /// Pass [videoPath] for local files, or [videoUrl] for files from network.
  /// Local files supports only Android
  Future<void> loadVideo({String? videoUrl, String? videoPath}) async {
    assert(
      videoUrl != null || videoPath != null,
      'Should provide videoPath or videoUrl',
    );

    final params = {'videoUrl': videoUrl, 'videoPath': videoPath};
    return _channel.invokeMethod('loadVideo', params);
  }

  /// Check current player state
  Future<bool> isPlaying() async {
    return await _channel.invokeMethod('isPlaying');
  }

  /// Play video
  Future<void> play() {
    return _channel.invokeMethod('play');
  }

  /// Pause video
  Future<void> pause() {
    return _channel.invokeMethod('pause');
  }

  /// Set player volume from 0 to 1
  Future<void> setVolume(double volume) async {
    try {
      return _channel.invokeMethod('setVolume', {'volume': volume});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('${e.code}: ${e.message}');
      }
    }
  }

  /// Enable/disable fullscreen mode
  /// Works only on Android.On IOS you need to pass
  /// new [VrPlayer.width] and [VrPlayer.height] to [VrPlayer] widget
  Future<void> fullScreen() {
    return _channel.invokeMethod('fullScreen');
  }

  /// Switch between 360 mode and VR mode
  Future<void> toggleVRMode() {
    return _channel.invokeMethod('toggleVRMode');
  }

  /// (Only for Android)
  /// Reload player when you need to change size of nativeView
  Future<void> onSizeChanged(double width, double height) {
    final newSize = HashMap<String, double>();
    newSize['width'] = width;
    newSize['height'] = height;
    return _channel.invokeMethod('onSizeChanged', newSize);
  }

  /// Seek to [position]
  Future<void> seekTo(int position) {
    final newPosition = HashMap<String, int>();
    newPosition['position'] = position;
    return _channel.invokeMethod('seekTo', newPosition);
  }

  /// (Only for Android)
  /// Dispose player on pause
  Future<void> onPause() {
    return _channel.invokeMethod('onPause');
  }

  /// (Only for Android)
  /// Reload player
  Future<void> onResume() {
    return _channel.invokeMethod('onResume');
  }

  /// (Only for Android)
  /// Notify player when orientation changed
  Future<void> onOrientationChanged() {
    return _channel.invokeMethod('onOrientationChanged');
  }
}

/// Enum for showing the player state
enum VrState {
  loading,
  ready,
  buffering,
  idle,
}

/// [VrPlayerObserver] is required for listening to player notifications
class VrPlayerObserver {
  late EventChannel _eventChannelState;
  late EventChannel _eventChannelDuration;
  late EventChannel _eventChannelPosition;
  late EventChannel _eventChannelEnded;

  late StreamSubscription _stateStreamSubscription;
  late StreamSubscription _positionStreamSubscription;
  late StreamSubscription _durationStreamSubscription;
  late StreamSubscription _endedStreamSubscription;

  /// Used to receive player events
  ValueChanged<VrState>? onStateChange;

  /// Used to receive video duration in millis
  ValueChanged<int>? onDurationChange;

  /// Used to receive current video position in millis
  ValueChanged<int>? onPositionChange;

  /// Invokes when video is ended
  ValueChanged<bool>? onFinishedChange;

  /// Init Stream Subscriptions to receive player events
  VrPlayerObserver.init(int id) {
    _eventChannelState = EventChannel('vr_player_events_${id}_state');
    _stateStreamSubscription =
        _eventChannelState.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onStateChange?.call(VrState.values[event['state']]);
    });

    _eventChannelDuration = EventChannel('vr_player_events_${id}_duration');
    _durationStreamSubscription =
        _eventChannelDuration.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onDurationChange?.call(event['duration']);
    });

    _eventChannelPosition = EventChannel('vr_player_events_${id}_position');
    _positionStreamSubscription =
        _eventChannelPosition.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onPositionChange?.call(event['currentPosition']);
    });

    _eventChannelEnded = EventChannel('vr_player_events_${id}_ended');
    _endedStreamSubscription =
        _eventChannelEnded.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onFinishedChange?.call(event['ended'] ?? false);
    });
  }

  /// Used to stop listening for updates
  void cancelListeners() {
    _stateStreamSubscription.cancel();
    _durationStreamSubscription.cancel();
    _positionStreamSubscription.cancel();
    _endedStreamSubscription.cancel();
  }
}

typedef VrPlayerCreatedCallback = void Function(
  VrPlayerController controller,
  VrPlayerObserver observer,
);

class VrPlayer extends StatefulWidget {
  final VrPlayerCreatedCallback onCreated;
  final double x;
  final double y;

  /// Make sure that the best aspect ratio is 2:1
  /// https://developers.google.com/vr/discover/360-degree-media
  final double width;
  final double height;

  const VrPlayer({
    required this.onCreated,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VrPlayer> with WidgetsBindingObserver {
  late VrPlayerController _videoPlayerController;
  late VrPlayerObserver _playerObserver;
  bool _wasResumed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(VrPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) {
      final pixelRatio =
          Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1;

      final width = widget.width * pixelRatio;
      final height = widget.height * pixelRatio;

      _videoPlayerController.onSizeChanged(width, height);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _wasResumed = true;
      await _videoPlayerController.onResume();
    } else if (state == AppLifecycleState.paused) {
      await _videoPlayerController.onPause();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      _playerObserver.cancelListeners();
      _videoPlayerController.pause();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeMetrics() async {
    super.didChangeMetrics();
    if (!_wasResumed) {
      await _videoPlayerController.onOrientationChanged();
    }
    _wasResumed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: _nativeView(),
    );
  }

  Widget _nativeView() {
    const viewType = 'plugins.vr_player/player_view';
    if (Platform.isAndroid) {
      return PlatformViewLink(
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
              Factory(TapGestureRecognizer.new)
            },
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            creationParams: {},
            creationParamsCodec: const StandardMessageCodec(),
            layoutDirection: TextDirection.ltr,
            viewType: viewType,
          )
                ..addOnPlatformViewCreatedListener(
                  params.onPlatformViewCreated,
                )
                ..addOnPlatformViewCreatedListener(onPlatformViewCreated)
                ..create(size: Size(widget.width, widget.height));
          return controller;
        },
        viewType: viewType,
      );
    } else {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{
          'x': widget.x,
          'y': widget.y,
          'width': widget.width,
          'height': widget.height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Future<void> onPlatformViewCreated(int id) async {
    _videoPlayerController = VrPlayerController.init(id);
    _playerObserver = VrPlayerObserver.init(id);
    widget.onCreated(_videoPlayerController, _playerObserver);
  }
}
