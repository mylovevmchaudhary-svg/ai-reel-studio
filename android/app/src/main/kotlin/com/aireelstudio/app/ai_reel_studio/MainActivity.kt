package com.aireelstudio.app.ai_reel_studio

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.aireelstudio.app/video_muxer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "createVideoFromImages") {
                val imagePaths = call.argument<List<String>>("imagePaths") ?: emptyList()
                val durations = call.argument<List<Double>>("durations") ?: emptyList()
                val outputPath = call.argument<String>("outputPath") ?: ""
                val fps = call.argument<Int>("fps") ?: 30

                Thread {
                    try {
                        encodeImagesToMp4(imagePaths, durations, outputPath, fps)
                        runOnUiThread {
                            result.success(outputPath)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("MUXER_ERROR", e.localizedMessage ?: "Unknown error", null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun encodeImagesToMp4(
        imagePaths: List<String>,
        durations: List<Double>,
        outputPath: String,
        fps: Int
    ) {
        val validPaths = imagePaths.filter { File(it).exists() }
        if (validPaths.isEmpty()) {
            throw IllegalArgumentException("No valid image files provided for video encoding")
        }

        // Determine dimensions
        val sampleBitmap = BitmapFactory.decodeFile(validPaths[0])
            ?: throw IllegalArgumentException("Cannot decode first image")
        var width = (sampleBitmap.width + 15) / 16 * 16
        var height = (sampleBitmap.height + 15) / 16 * 16
        sampleBitmap.recycle()

        // Clamp to standard max 1080p for compatibility
        if (width > 1080 && height > 1920) {
            width = 1080
            height = 1920
        }

        val mimeType = "video/avc"
        val bitrate = 3000000 // 3 Mbps
        val format = MediaFormat.createVideoFormat(mimeType, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        val codec = MediaCodec.createEncoderByType(mimeType)
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = codec.createInputSurface()
        codec.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_FORMAT_MP4)
        var trackIndex = -1
        var muxerStarted = false

        val bufferInfo = MediaCodec.BufferInfo()
        var currentPresentationTimeUs = 0L
        val frameDurationUs = (1000000L / fps)

        for (i in validPaths.indices) {
            val file = File(validPaths[i])
            if (!file.exists()) continue
            val original = BitmapFactory.decodeFile(file.absolutePath) ?: continue
            val scaled = if (original.width != width || original.height != height) {
                Bitmap.createScaledBitmap(original, width, height, true)
            } else {
                original
            }

            val durationSec = if (i < durations.size) durations[i] else 4.0
            val totalFrames = (durationSec * fps).toInt().coerceAtLeast(1)

            for (f in 0 until totalFrames) {
                val canvas: Canvas = inputSurface.lockCanvas(null)
                canvas.drawColor(Color.BLACK)
                canvas.drawBitmap(scaled, 0f, 0f, null)
                inputSurface.unlockCanvasAndPost(canvas)

                currentPresentationTimeUs += frameDurationUs

                drainEncoder(codec, muxer, bufferInfo, false) {
                    if (!muxerStarted) {
                        trackIndex = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    trackIndex
                }
            }

            if (scaled != original) scaled.recycle()
            original.recycle()
        }

        codec.signalEndOfInputStream()
        drainEncoder(codec, muxer, bufferInfo, true) { trackIndex }

        try {
            codec.stop()
            codec.release()
        } catch (_: Exception) {}

        if (muxerStarted) {
            try {
                muxer.stop()
                muxer.release()
            } catch (_: Exception) {}
        }
    }

    private fun drainEncoder(
        codec: MediaCodec,
        muxer: MediaMuxer,
        bufferInfo: MediaCodec.BufferInfo,
        endOfStream: Boolean,
        getTrackIndex: () -> Int
    ) {
        val timeoutUsec = 10000L
        while (true) {
            val encoderStatus = codec.dequeueOutputBuffer(bufferInfo, timeoutUsec)
            if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                getTrackIndex()
            } else if (encoderStatus >= 0) {
                val encodedData = codec.getOutputBuffer(encoderStatus)
                    ?: throw RuntimeException("Encoder buffer was null")

                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                    bufferInfo.size = 0
                }

                if (bufferInfo.size != 0) {
                    val trackIndex = getTrackIndex()
                    encodedData.position(bufferInfo.offset)
                    encodedData.limit(bufferInfo.offset + bufferInfo.size)
                    muxer.writeSampleData(trackIndex, encodedData, bufferInfo)
                }

                codec.releaseOutputBuffer(encoderStatus, false)
                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    break
                }
            }
        }
    }
}
