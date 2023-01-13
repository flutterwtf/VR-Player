
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import wtf.flutter.vr_player.R
import wtf.flutter.vr_player.VideoPlayerController
import com.kaltura.playkit.player.PKHttpClientManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class VideoView internal constructor(private val context: Context, viewId: Int, args: Any?, binaryMessenger: BinaryMessenger) : PlatformView {
    private var playerView: FrameLayout? = null
    private var videoPlayerController = VideoPlayerController(context, object: VideoPlayerController.ViewCreatedListener {
        override fun onViewCreated(view: View) {
            playerView?.removeAllViews()
            playerView?.addView(view)
        }

        override fun changeViewSize(args: HashMap<*, *>) {
            updateViewSize(args)
        }
    }, viewId, binaryMessenger)

    private val innerView: View by lazy {
        LayoutInflater.from(context).inflate(R.layout.video_view, null).apply {
            playerView = findViewById(R.id.player_view)
            videoPlayerController.loadPlayer()
            (args as? HashMap<*, *>)?.let {
                updateViewSize(it)
            }
        }
    }

    private fun updateViewSize(args: java.util.HashMap<*, *>) {
        if (args.containsKey("width") && args["width"] is Double && args.containsKey("height") && args["height"] is Double) {
            playerView?.layoutParams = LinearLayout.LayoutParams((args["width"] as Double).toInt(), (args["height"] as Double).toInt())
        }
    }

    override fun getView(): View {
        return innerView
    }

    override fun dispose() {
        videoPlayerController.dispose()
    }

    override fun onFlutterViewDetached() {
        super.onFlutterViewDetached()
        videoPlayerController.dispose()
    }

    private fun initializePlayer() {
      //  val playerInitOptions = PlayerInitOptions()
      //  val player = KalturaBasicPlayer.create(context, playerInitOptions)
      //  doConnectionsWarmup(ovpServerUrl)
        videoPlayerController.loadPlayer()
    }

    private fun doConnectionsWarmup(ovpServerUrl: String) {
        PKHttpClientManager.setHttpProvider("okhttp")
        PKHttpClientManager.warmUp(ovpServerUrl)
    }
}

class VideoViewFactory(private val binaryMessenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        return VideoView(context!!, viewId, args, binaryMessenger)
    }
}
