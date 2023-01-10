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
  late VrPlayerController viewPlayerController;
  late AnimationController animationController;
  late Animation<double> animation;
  bool isShowingBar = false;
  bool isPlaying = false;
  bool isFullScreen = false;
  bool videoEnded = false;
  double? playerWidth;
  double? playerHeight;
  String? duration;
  int? intDuration;
  bool? videoLoading;
  bool? videoReady;
  String? currentPosition;
  double? seekPosition = 0.0;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation = Tween(begin: 0.0, end: 1.0).animate(animationController);
    showingBar();
    super.initState();
  }

  showingBar() {
    isShowingBar = !isShowingBar;
    if (isShowingBar) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    playerWidth = MediaQuery.of(context).size.width;
    playerHeight = isFullScreen ? MediaQuery.of(context).size.height : playerWidth! * 9.0 / 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("VR Player"),
      ),
      body: GestureDetector(
        onTap: () {
          print('REVERSE ANIMATION');
          showingBar();
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VrPlayer(
              x: 0,
              y: 0,
              onCreated: onViewPlayerCreated,
              width: playerWidth,
              height: playerHeight,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: animation,
                child: Container(
                  color: Colors.black,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(
                            this.videoEnded
                                ? Icons.replay
                                : isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: playAndPause),
                      Text(
                        currentPosition?.toString() ?? '00:00',
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
                              value: seekPosition!,
                              max: intDuration == null ? 0.0 : intDuration!.toDouble(),
                              onChangeEnd: (value) {
                                viewPlayerController.seekTo(value.toInt());
                              },
                              onChanged: (value) {
                                onChangePosition(value.toInt());
                              }),
                        ),
                      ),
                      Text(
                        duration?.toString() ?? '99:99',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                          icon: Icon(
                            isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: fullScreenPressed),
                      isFullScreen
                          ? IconButton(
                              icon: Image.asset('assets/icons/cardboard.png', color: Colors.white),
                              onPressed: cardBoardPressed)
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
    this.viewPlayerController.toggleVRMode();
  }

  void fullScreenPressed() async {
    await this.viewPlayerController.fullScreen();
    setState(() {
      isFullScreen = !isFullScreen;
    });

    if (isFullScreen) {
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
    if (this.videoEnded) {
      await viewPlayerController.seekTo(0);
    }

    if (isPlaying) {
      await viewPlayerController.pause();
    } else {
      await viewPlayerController.play();
    }

    setState(() {
      isPlaying = !isPlaying;
      this.videoEnded = false;
    });
  }

  void onViewPlayerCreated(VrPlayerController controller, VrPlayerObserver observer) {
    this.viewPlayerController = controller;
    observer.handleStateChange(this.onReceiveState);
    observer.handleDurationChange(this.onReceiveDuration);
    observer.handlePositionChange(this.onReceivePosition);
    observer.handleEndedChange(this.onReceiveEnded);
    this.viewPlayerController.loadVideo(
        videoUrl: "https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8");
  }

  void onReceiveState(Map event) {
    switch (event["state"]) {
      case 0:
        {
          setState(() {
            this.videoLoading = true;
          });
          break;
        }
      case 1:
        {
          setState(() {
            this.videoLoading = false;
            this.videoReady = true;
          });
          break;
        }
      case 2:
        {
          // buffering
          break;
        }
    }
  }

  void onReceiveDuration(Map event) {
    setState(() {
      intDuration = event['duration'];
      this.duration = milisecondsToDateTime(event['duration']);
    });
  }

  void onReceivePosition(Map event) {
    onChangePosition(event['currentPosition']);
  }

  void onChangePosition(position) {
    setState(() {
      this.currentPosition = milisecondsToDateTime(position);
      seekPosition = position.toDouble();
    });
  }

  void onReceiveEnded(Map event) {
    setState(() {
      this.videoEnded = event["ended"] ?? false;
    });
  }

  String milisecondsToDateTime(int miliseconds) =>
      setDurationText(Duration(milliseconds: miliseconds));

  String setDurationText(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    super.dispose();
  }
}
