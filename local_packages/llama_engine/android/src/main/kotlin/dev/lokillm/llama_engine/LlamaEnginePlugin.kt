package dev.lokillm.llama_engine

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Flutter plugin exposing llama.cpp GGUF inference over a MethodChannel (control)
 * and an EventChannel (token stream). All native work runs on a single-thread
 * executor so llama.cpp state is touched from one thread; the stop flag is set
 * lock-free natively.
 */
class LlamaEnginePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var isGenerating = false

    companion object {
        init {
            System.loadLibrary("llama_engine_jni")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "llama_engine")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "llama_engine/stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        executor.shutdown()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "loadModel" -> loadModel(call, result)
            "generateStream" -> generateStream(call, result)
            "stopGeneration" -> {
                nativeStopGeneration()
                result.success(null)
            }
            "unloadModel" -> {
                executor.execute {
                    nativeFreeModel()
                    mainHandler.post { result.success(null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun loadModel(call: MethodCall, result: Result) {
        val path = call.argument<String>("modelPath")
        if (path == null) {
            result.error("INVALID_ARGS", "Missing modelPath", null)
            return
        }
        val nThreads = call.argument<Int>("nThreads") ?: 4
        val contextSize = call.argument<Int>("contextSize") ?: 2048
        val batchSize = call.argument<Int>("batchSize") ?: 512
        executor.execute {
            val ok = nativeInitModel(path, nThreads, contextSize, batchSize)
            mainHandler.post { result.success(ok) }
        }
    }

    private fun generateStream(call: MethodCall, result: Result) {
        val prompt = call.argument<String>("prompt")
        if (prompt == null) {
            result.error("INVALID_ARGS", "Missing prompt", null)
            return
        }
        val temperature = call.argument<Double>("temperature")?.toFloat() ?: 0.7f
        val topP = call.argument<Double>("topP")?.toFloat() ?: 0.95f
        val topK = call.argument<Int>("topK") ?: 40
        val maxTokens = call.argument<Int>("maxTokens") ?: 512
        val repeatPenalty = call.argument<Double>("repeatPenalty")?.toFloat() ?: 1.1f
        val stopSequences =
            (call.argument<List<String>>("stopSequences") ?: emptyList()).toTypedArray()
        val grammar = call.argument<String>("grammar")

        // Wait briefly for the EventChannel's onListen to install the sink,
        // since listen and invoke ride separate channels and can reorder.
        var sink = eventSink
        val deadline = System.currentTimeMillis() + 1000
        while (sink == null && System.currentTimeMillis() < deadline) {
            Thread.sleep(20)
            sink = eventSink
        }
        val resolvedSink = sink
        if (resolvedSink == null) {
            result.error("NO_EVENT_SINK", "Event channel not initialized", null)
            return
        }

        if (isGenerating) {
            result.error("BUSY", "Generation already in progress", null)
            return
        }
        isGenerating = true

        executor.execute {
            try {
                nativeGenerateStreamInit(
                    prompt, temperature, topP, topK, maxTokens, repeatPenalty,
                    stopSequences, grammar
                )
                while (true) {
                    val token = nativeGenerateStreamNext() ?: break
                    mainHandler.post { resolvedSink.success(token) }
                }
                nativeGenerateStreamEnd()
                mainHandler.post {
                    resolvedSink.endOfStream()
                    result.success(null)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    resolvedSink.error("EXCEPTION", e.message, null)
                    result.error("EXCEPTION", e.message, null)
                }
            } finally {
                isGenerating = false
            }
        }
    }

    // --- JNI ---
    private external fun nativeInitModel(
        modelPath: String, nThreads: Int, contextSize: Int, batchSize: Int
    ): Boolean

    private external fun nativeGenerateStreamInit(
        prompt: String, temperature: Float, topP: Float, topK: Int,
        maxTokens: Int, repeatPenalty: Float, stopSequences: Array<String>,
        grammar: String?,
    )

    private external fun nativeGenerateStreamNext(): String?
    private external fun nativeGenerateStreamEnd()
    private external fun nativeStopGeneration()
    private external fun nativeFreeModel()
}
