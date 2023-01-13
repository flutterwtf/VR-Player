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

class _VideoPlayerPageState extends State<VideoPlayerPage> with TickerProviderStateMixin {
  late VrPlayerController _viewPlayerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingBar = false;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isVideoFinished = false;
  late double _playerWidth;
  late double _playerHeight;
  String? _duration;
  int? _intDuration;
  bool isVideoLoading = false;
  bool isVideoReady = false;
  String? _currentPosition;
  double? _seekPosition = 0.0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _toggleShowingBar();
    super.initState();
  }

  void _toggleShowingBar() {
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
    _playerHeight = _isFullScreen ? MediaQuery.of(context).size.height : _playerWidth / 2.0;

    return Scaffold(
      appBar: AppBar(title: Text("VR Player")),
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
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                            overlayColor: Colors.purple.withAlpha(32),
                            overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
                          ),
                          child: Slider(
                            value: _seekPosition!,
                            max: _intDuration == null ? 0.0 : _intDuration!.toDouble(),
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
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
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
            )
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
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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

  void onViewPlayerCreated(VrPlayerController controller, VrPlayerObserver observer) {
    this._viewPlayerController = controller;
    observer.handleStateChange(this.onReceiveState);
    observer.handleDurationChange(this.onReceiveDuration);
    observer.handlePositionChange(this.onReceivePosition);
    observer.handleEndedChange(this.onReceiveEnded);
    this._viewPlayerController.loadVideo(
          videoUrl: "https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8",
        );
  }

  void onReceiveState(Map event) {
    switch (event["state"]) {
      case 0:
        // Loading
        setState(() {
          this.isVideoLoading = true;
        });
        break;
      case 1:
        // Ready
        setState(() {
          this.isVideoLoading = false;
          this.isVideoReady = true;
        });
        break;
      case 2:
        // Buffering
        break;
    }
  }

  void onReceiveDuration(Map<String, dynamic> event) {
    setState(() {
      _intDuration = event['duration'];
      this._duration = millisecondsToDateTime(event['duration']);
    });
  }

  void onReceivePosition(Map<String, dynamic> event) {
    onChangePosition(event['currentPosition']);
  }

  void onChangePosition(position) {
    setState(() {
      this._currentPosition = millisecondsToDateTime(position);
      _seekPosition = position.toDouble();
    });
  }

  void onReceiveEnded(Map event) {
    setState(() {
      this._isVideoFinished = event["ended"] ?? false;
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
