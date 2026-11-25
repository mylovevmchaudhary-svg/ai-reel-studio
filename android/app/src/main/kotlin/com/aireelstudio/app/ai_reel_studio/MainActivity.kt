package com.aireelstudio.app.ai_reel_studio

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

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
                val audioPath = call.argument<String>("audioPath")

                Thread {
                    try {
                        encodeVideo(imagePaths, durations, outputPath, fps, audioPath)
                        runOnUiThread {
                            result.success(outputPath)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        runOnUiThread {
                            result.error("MUXER_ERROR", e.localizedMessage ?: "Encoding failed", null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun encodeVideo(
        imagePaths: List<String>,
        durations: List<Double>,
        outputPath: String,
        fps: Int,
        audioPath: String?
    ) {
        val validPaths = imagePaths.filter { File(it).exists() }
        if (validPaths.isEmpty()) {
            throw IllegalArgumentException("No valid image files provided for video encoding")
        }

        // 1. Determine optimal dimensions (multiples of 16 for universal H.264 hardware support)
        val sampleBitmap = BitmapFactory.decodeFile(validPaths[0])
            ?: throw IllegalArgumentException("Cannot decode first image")
        var width = (sampleBitmap.width / 16) * 16
        var height = (sampleBitmap.height / 16) * 16
        sampleBitmap.recycle()

        if (width < 320) width = 720
        if (height < 320) height = 1280
        if (width > 1080) width = 1080
        if (height > 1920) height = 1920

        val mimeType = "video/avc"
        val bitrate = 4000000 // 4 Mbps high quality
        val codec = MediaCodec.createEncoderByType(mimeType)
        val capabilities = codec.codecInfo.getCapabilitiesForType(mimeType)
        val supportedFormats = capabilities.colorFormats

        val isSemiPlanar = supportedFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)
        val chosenColorFormat = if (isSemiPlanar) {
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar
        } else if (supportedFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar)) {
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar
        } else {
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible
        }

        val videoFormat = MediaFormat.createVideoFormat(mimeType, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, chosenColorFormat)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        codec.configure(videoFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        codec.start()

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var videoTrackIndex = -1
        var audioTrackIndex = -1
        var muxerStarted = false

        // Audio Extractor setup if audioPath provided
        var audioExtractor: MediaExtractor? = null
        var audioTrackInExtractor = -1
        if (!audioPath.isNullOrEmpty() && File(audioPath).exists()) {
            try {
                val extractor = MediaExtractor()
                extractor.setDataSource(audioPath)
                for (i in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("audio/")) {
                        audioTrackInExtractor = i
                        audioTrackIndex = muxer.addTrack(format)
                        extractor.selectTrack(i)
                        audioExtractor = extractor
                        break
                    }
                }
            } catch (e: Exception) {
                audioExtractor = null
            }
        }

        val bufferInfo = MediaCodec.BufferInfo()
        var currentPresentationTimeUs = 0L
        val frameDurationUs = (1000000L / fps)

        try {
            for (i in validPaths.indices) {
                val file = File(validPaths[i])
                if (!file.exists()) continue
                val original = BitmapFactory.decodeFile(file.absolutePath) ?: continue
                val scaled = if (original.width != width || original.height != height) {
                    Bitmap.createScaledBitmap(original, width, height, true)
                } else {
                    original
                }

                // Convert bitmap to YUV420 once per scene
                val yuvData = rgbToYuv420(scaled, width, height, isSemiPlanar)
                if (scaled != original) scaled.recycle()
                original.recycle()

                val durationSec = if (i < durations.size) durations[i] else 3.0
                val totalFrames = (durationSec * fps).toInt().coerceAtLeast(1)

                for (f in 0 until totalFrames) {
                    // Feed YUV frame to encoder
                    var inputFed = false
                    while (!inputFed) {
                        val inputBufferIndex = codec.dequeueInputBuffer(10000L)
                        if (inputBufferIndex >= 0) {
                            val inputBuffer = codec.getInputBuffer(inputBufferIndex)
                                ?: throw RuntimeException("Encoder input buffer was null")
                            inputBuffer.clear()
                            inputBuffer.put(yuvData)
                            codec.queueInputBuffer(inputBufferIndex, 0, yuvData.size, currentPresentationTimeUs, 0)
                            inputFed = true
                        }

                        // Drain pending output
                        drainEncoder(codec, muxer, bufferInfo, false) {
                            if (!muxerStarted) {
                                videoTrackIndex = muxer.addTrack(codec.outputFormat)
                                muxer.start()
                                muxerStarted = true
                            }
                            videoTrackIndex
                        }
                    }

                    currentPresentationTimeUs += frameDurationUs
                }
            }

            // Signal End of Stream
            var eosQueued = false
            while (!eosQueued) {
                val inputBufferIndex = codec.dequeueInputBuffer(10000L)
                if (inputBufferIndex >= 0) {
                    codec.queueInputBuffer(inputBufferIndex, 0, 0, currentPresentationTimeUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    eosQueued = true
                }
                drainEncoder(codec, muxer, bufferInfo, false) {
                    if (!muxerStarted) {
                        videoTrackIndex = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    videoTrackIndex
                }
            }

            // Drain remaining EOS output
            drainEncoder(codec, muxer, bufferInfo, true) { videoTrackIndex }

            // Mux audio samples if audioExtractor is active
            if (audioExtractor != null && audioTrackIndex >= 0 && muxerStarted) {
                try {
                    val audioBuffer = ByteBuffer.allocate(64 * 1024)
                    val audioBufferInfo = MediaCodec.BufferInfo()
                    while (true) {
                        val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)
                        if (sampleSize < 0) break

                        audioBufferInfo.offset = 0
                        audioBufferInfo.size = sampleSize
                        audioBufferInfo.presentationTimeUs = audioExtractor.sampleTime
                        audioBufferInfo.flags = audioExtractor.sampleFlags

                        muxer.writeSampleData(audioTrackIndex, audioBuffer, audioBufferInfo)
                        audioExtractor.advance()
                    }
                } catch (_: Exception) {}
            }

        } finally {
            try {
                codec.stop()
                codec.release()
            } catch (_: Exception) {}

            try {
                audioExtractor?.release()
            } catch (_: Exception) {}

            if (muxerStarted) {
                try {
                    muxer.stop()
                    muxer.release()
                } catch (_: Exception) {}
            }
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
                    if (trackIndex >= 0) {
                        encodedData.position(bufferInfo.offset)
                        encodedData.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(trackIndex, encodedData, bufferInfo)
                    }
                }

                codec.releaseOutputBuffer(encoderStatus, false)
                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    break
                }
            }
        }
    }

    private fun rgbToYuv420(bitmap: Bitmap, width: Int, height: Int, isSemiPlanar: Boolean): ByteArray {
        val frameSize = width * height
        val yuv = ByteArray(frameSize * 3 / 2)
        val argb = IntArray(frameSize)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        var yIndex = 0
        var uIndex = frameSize
        var vIndex = frameSize + (frameSize / 4)

        for (j in 0 until height) {
            for (i in 0 until width) {
                val c = argb[j * width + i]
                val r = (c shr 16) and 0xff
                val g = (c shr 8) and 0xff
                val b = c and 0xff

                val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yuv[yIndex++] = (y.coerceIn(16, 235)).toByte()

                if (j % 2 == 0 && i % 2 == 0) {
                    val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128

                    if (isSemiPlanar) {
                        yuv[uIndex++] = (u.coerceIn(16, 240)).toByte()
                        yuv[uIndex++] = (v.coerceIn(16, 240)).toByte()
                    } else {
                        yuv[uIndex++] = (u.coerceIn(16, 240)).toByte()
                        yuv[vIndex++] = (v.coerceIn(16, 240)).toByte()
                    }
                }
            }
        }
        return yuv
    }
}
