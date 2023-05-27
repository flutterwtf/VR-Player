part of 'vr_player.dart';

/// [VrPlayerObserver] is required for listening to player notifications
class VrPlayerObserver {
  /// Used to receive player events
  ValueChanged<VrState>? onStateChange;

  /// Used to receive video duration in millis
  ValueChanged<int>? onDurationChange;

  /// Used to receive current video position in millis
  ValueChanged<int>? onPositionChange;

  /// Invokes when video is ended
  ValueChanged<bool>? onFinishedChange;

  late EventChannel _eventChannelState;
  late EventChannel _eventChannelDuration;
  late EventChannel _eventChannelPosition;
  late EventChannel _eventChannelEnded;

  late StreamSubscription _stateSubscription;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _endedSubscription;

  /// Init Stream Subscriptions to receive player events
  VrPlayerObserver.init(int id) {
    _eventChannelState = EventChannel('vr_player_events_${id}_state');
    _stateSubscription =
        _eventChannelState.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onStateChange?.call(VrState.values[event['state']]);
    });

    _eventChannelDuration = EventChannel('vr_player_events_${id}_duration');
    _durationSubscription =
        _eventChannelDuration.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onDurationChange?.call(event['duration']);
    });

    _eventChannelPosition = EventChannel('vr_player_events_${id}_position');
    _positionSubscription =
        _eventChannelPosition.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onPositionChange?.call(event['currentPosition']);
    });

    _eventChannelEnded = EventChannel('vr_player_events_${id}_ended');
    _endedSubscription =
        _eventChannelEnded.receiveBroadcastStream().listen((event) {
      // ignore: avoid_dynamic_calls
      onFinishedChange?.call(event['ended'] ?? false);
    });
  }

  /// Used to stop listening for updates
  void cancelListeners() {
    _stateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _endedSubscription.cancel();
  }
}
