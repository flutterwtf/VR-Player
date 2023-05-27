part of 'vr_player.dart';

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
    await _channel.invokeMethod('loadVideo', params);
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
      await _channel.invokeMethod('setVolume', {'volume': volume});
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
