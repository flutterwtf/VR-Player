# VrPlayer

VR Player Plugin for Flutter

## Getting Started

Based on Kaltura Playkit SDK.

The `VrPlayer` plugin lets you play 360° and VR videos smoothly on Android and iOS platforms, delivering an immersive viewing experience with touch and device motion controls. These types of videos, commonly referred to as immersive, 360, or spherical videos, are captured by utilizing an omnidirectional camera or multiple cameras to record the entire panoramic view simultaneously.
## Usage

```dart
VrPlayer(
  x: 0,
  y: 0,
  onCreated: onViewPlayerCreated,
  width: playerWidth,
  height: playerHeight,
),
```
You must implement `onViewPlayerCreated` to receive player events.

```dart
void onViewPlayerCreated(
  VrPlayerController controller
  VrPlayerObserver observer
) {
  this.viewPlayerController = controller;
  /// Receive player state [loading, ready, buffering]
  observer.handleStateChange(this.onReceiveState);
  /// Receive duration in millis
  observer.handleDurationChange(this.onReceiveDuration);
  /// Receive current position in millis
  observer.handlePositionChange(this.onReceivePosition);
  /// Receive when video is finished
  observer.handleFinishedChange(this.onReceiveFinished);
  this.viewPlayerController.loadVideo(
    videoUrl: "https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8"
  );
}
```
### VrPlayerController

The `VrPlayerController` can be used to change the state of a `VrPlayer`  Note that the methods can only be used after the `VrPlayer` has been created.

 Method | Description 
--- | ---
`loadVideo({String? videoUrl, String? videoPath})` | Initializes video based on configuration. Invoke actions which need to be run on player start. Pass `videoPath` to load local files, or `videoUrl` to play files from network. *Local files supports only Android.*
`isPlaying()` | Check current player state.
`play()` | Play video.
`pause()` | Pause video.
`seekTo()` | Seek to position.
`setVolume()` | Set video volume level from 0 (no sound) to 1 (max).
`fullScreen()` | *(Android only)* Enable/disable fullscreen mode.  On IOS  you need to pass new width and height to VrPlayer widget
`toggleVRMode()` | Switch between 360° mode and VR mode. 
`onSizeChanged()` | *(Android only)* Reload player when you need to change size of nativeView.
`onPause()` | *(Android only)* Dispose player on pause.
`onResume()` | *(Android only)* Reload player.
`onOrientationChanged()` | *(Android only)* Notily player when orientation changed.

## License Information  

All code in this project is released under the [AGPLv3 license](https://www.gnu.org/licenses/agpl-3.0.html) unless a different license for a particular library is specified in the applicable library path.   

## Contribution

This repository welcomes contributions from the community! Whether you're looking to fix bugs, improve existing features, or add new ones, we would be happy to review and merge your contributions.