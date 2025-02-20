import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vr_player/vr_player.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: const Key("start_video_button"),
      onPressed: buttonOnPressed,
      child: const Text('Start Video'),
    );
  }

  void buttonOnPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoPlayerPage(),
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> with TickerProviderStateMixin {
  late VrPlayerController _viewPlayerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingBar = false;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isVideoFinished = false;
  bool _isVideoLoaded = false;
  bool _isLandscapeOrientation = false;
  bool _isVolumeSliderShown = false;
  bool _isVolumeEnabled = true;
  String? _duration;
  int? _intDuration;
  bool isVideoLoading = false;
  bool isVideoReady = false;
  String? _currentPosition;
  double _currentSliderValue = 0.1;
  double _seekPosition = 0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _toggleShowingBar();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (Platform.isAndroid) {
      _viewPlayerController.onPause();
    }
    super.dispose();
  }

  void _toggleShowingBar() {
    switchVolumeSliderDisplay(show: false);

    _isShowingBar = !_isShowingBar;
    if (_isShowingBar) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLandscapeOrientation = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VR Player'),
      ),
      body: GestureDetector(
        onTap: _toggleShowingBar,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VrPlayer(
              key: const Key("vr_player"),
              x: 0,
              y: 0,
              onCreated: onViewPlayerCreated,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 9 / 16,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animation,
                child: ColoredBox(
                  color: Colors.black,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        key: const Key("play_pause_button"),
                        icon: Icon(
                          _isVideoFinished
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
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.amberAccent,
                            inactiveTrackColor: Colors.grey,
                            trackHeight: 5,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayColor: Colors.purple.withAlpha(32),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                          ),
                          child: Slider(
                            value: _seekPosition,
                            max: _intDuration?.toDouble() ?? 0,
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
                        key: const Key("duration_text"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_isFullScreen || _isLandscapeOrientation)
                        IconButton(
                          icon: Icon(
                            _isVolumeEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => switchVolumeSliderDisplay(show: true),
                        ),
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: fullScreenPressed,
                      ),
                      if (_isFullScreen)
                        IconButton(
                          icon: Image.asset(
                            'assets/icons/cardboard.png',
                            color: Colors.white,
                          ),
                          onPressed: cardBoardPressed,
                        )
                      else
                        Container(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              height: 180,
              right: 4,
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
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void cardBoardPressed() {
    _viewPlayerController.toggleVRMode();
  }

  Future<void> fullScreenPressed() async {
    if (Platform.isAndroid) {
      await _viewPlayerController.fullScreen();
    }

    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [],
      );
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  Future<void> playAndPause() async {
    if (_isVideoFinished) {
      await _viewPlayerController.seekTo(0);
    }

    if (_isPlaying) {
      await _viewPlayerController.pause();
    } else {
      await _viewPlayerController.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
      _isVideoFinished = false;
    });
  }

  void onViewPlayerCreated(
    VrPlayerController controller,
    VrPlayerObserver observer,
  ) async {
    _viewPlayerController = controller;
    observer
      ..onStateChange = onReceiveState
      ..onDurationChange = onReceiveDuration
      ..onPositionChange = onChangePosition
      ..onFinishedChange = onReceiveEnded;
    if (!_isVideoLoaded) {
      Future.delayed(Duration.zero, () async {
        await _viewPlayerController.loadVideo(
          videoUrl: 'https://cdn.deinerstertag.de/video/OKO_TECH-Industriemechaniker_in-KE-GR-V01/HLS/master.m3u8',
        );
        if (!mounted) return;
        setState(() {
          _isVideoLoaded = true;
        });
      });
    }
  }

  void onReceiveState(VrState state) {
    if (!mounted) return;
    switch (state) {
      case VrState.loading:
        setState(() {
          isVideoLoading = true;
        });
      case VrState.ready:
        setState(() {
          isVideoLoading = false;
          isVideoReady = true;
        });
      case VrState.buffering:
      case VrState.idle:
        break;
    }
  }

  void onReceiveDuration(int millis) {
    if (!mounted) return;
    setState(() {
      _intDuration = millis;
      _duration = millisecondsToDateTime(millis);
    });
  }

  void onChangePosition(int millis) {
    if (!mounted) return;
    setState(() {
      _currentPosition = millisecondsToDateTime(millis);
      _seekPosition = millis.toDouble();
    });
  }

  // ignore: avoid_positional_boolean_parameters
  void onReceiveEnded(bool isFinished) {
    if (!mounted) return;
    setState(() {
      _isVideoFinished = isFinished;
    });
  }

  void onChangeVolumeSlider(double value) {
    _viewPlayerController.setVolume(value);
    setState(() {
      _isVolumeEnabled = value != 0;
      _currentSliderValue = value;
    });
  }

  void switchVolumeSliderDisplay({required bool show}) {
    setState(() {
      _isVolumeSliderShown = show;
    });
  }

  String millisecondsToDateTime(int milliseconds) => setDurationText(Duration(milliseconds: milliseconds));

  String setDurationText(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
