import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vr_player/vr_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: buttonOnPressed,
      child: Text("Start Video"),
    );
  }

  void buttonOnPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(),
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin {
  late VrPlayerController _viewPlayerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingBar = false;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isVideoFinished = false;
  bool _isLandscapeOrientation = false;
  bool _isVolumeSliderShown = false;
  bool _isVolumeEnabled = true;
  late double _playerWidth;
  late double _playerHeight;
  String? _duration;
  int? _intDuration;
  bool isVideoLoading = false;
  bool isVideoReady = false;
  String? _currentPosition;
  double? _seekPosition = 0.0;
  double _currentSliderValue = 0.1;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _toggleShowingBar();
    super.initState();
  }

  void _toggleShowingBar() {
    switchVolumeSliderDisplay(false);

    _isShowingBar = !_isShowingBar;
    if (_isShowingBar) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    _playerWidth = MediaQuery.of(context).size.width;
    _playerHeight =
        _isFullScreen ? MediaQuery.of(context).size.height : _playerWidth / 2.0;
    _isLandscapeOrientation =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text("VR Player"),
      ),
      body: GestureDetector(
        onTap: () => _toggleShowingBar(),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VrPlayer(
              x: 0,
              y: 0,
              onCreated: onViewPlayerCreated,
              width: _playerWidth,
              height: _playerHeight,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  color: Colors.black,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          this._isVideoFinished
                              ? Icons.replay
                              : _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: playAndPause,
                      ),
                      Text(
                        _currentPosition?.toString() ?? '00:00',
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.amberAccent,
                            inactiveTrackColor: Colors.grey,
                            trackHeight: 5.0,
                            thumbColor: Colors.white,
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8.0),
                            overlayColor: Colors.purple.withAlpha(32),
                            overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 14.0),
                          ),
                          child: Slider(
                            value: _seekPosition!,
                            max: _intDuration?.toDouble() ?? 0.0,
                            onChangeEnd: (value) {
                              _viewPlayerController.seekTo(value.toInt());
                            },
                            onChanged: (value) {
                              onChangePosition(value.toInt());
                            },
                          ),
                        ),
                      ),
                      Text(
                        _duration?.toString() ?? '99:99',
                        style: TextStyle(color: Colors.white),
                      ),
                      if (_isFullScreen || _isLandscapeOrientation)
                        IconButton(
                          icon: Icon(
                            _isVolumeEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => switchVolumeSliderDisplay(true),
                        ),
                      IconButton(
                        icon: Icon(
                          _isFullScreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: fullScreenPressed,
                      ),
                      _isFullScreen
                          ? IconButton(
                              icon: Image.asset(
                                'assets/icons/cardboard.png',
                                color: Colors.white,
                              ),
                              onPressed: cardBoardPressed,
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              height: 180.0,
              right: 4.0,
              top: MediaQuery.of(context).size.height / 4,
              child: _isVolumeSliderShown
                  ? RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _currentSliderValue,
                        divisions: 10,
                        onChanged: onChangeVolumeSlider,
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void cardBoardPressed() {
    this._viewPlayerController.toggleVRMode();
  }

  void fullScreenPressed() async {
    await this._viewPlayerController.fullScreen();
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [],
      );
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void playAndPause() async {
    if (this._isVideoFinished) {
      await _viewPlayerController.seekTo(0);
    }

    if (_isPlaying) {
      await _viewPlayerController.pause();
    } else {
      await _viewPlayerController.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
      this._isVideoFinished = false;
    });
  }

  void onViewPlayerCreated(
    VrPlayerController controller,
    VrPlayerObserver observer,
  ) {
    this._viewPlayerController = controller;
    observer.handleStateChange(this.onReceiveState);
    observer.handleDurationChange(this.onReceiveDuration);
    observer.handlePositionChange(this.onChangePosition);
    observer.handleFinishedChange(this.onReceiveEnded);
    this._viewPlayerController.loadVideo(
          videoUrl:
              "https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8",
        );
  }

  void onReceiveState(VrState state) {
    switch (state) {
      case VrState.loading:
        setState(() {
          this.isVideoLoading = true;
        });
        break;
      case VrState.ready:
        setState(() {
          this.isVideoLoading = false;
          this.isVideoReady = true;
        });
        break;
      case VrState.buffering:
      case VrState.idle:
        break;
    }
  }

  void onReceiveDuration(int millis) {
    setState(() {
      _intDuration = millis;
      this._duration = millisecondsToDateTime(millis);
    });
  }

  void onChangePosition(int millis) {
    setState(() {
      this._currentPosition = millisecondsToDateTime(millis);
      _seekPosition = millis.toDouble();
    });
  }

  void onReceiveEnded(bool isFinished) {
    setState(() {
      this._isVideoFinished = isFinished;
    });
  }

  void onChangeVolumeSlider(double value) {
    _viewPlayerController.setVolume(value);
    setState(() {
      _isVolumeEnabled = value != 0.0;
      _currentSliderValue = value;
    });
  }

  void switchVolumeSliderDisplay(bool show) {
    setState(() {
      _isVolumeSliderShown = show;
    });
  }

  String millisecondsToDateTime(int milliseconds) =>
      setDurationText(Duration(milliseconds: milliseconds));

  String setDurationText(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
