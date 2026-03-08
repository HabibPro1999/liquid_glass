package com.liquidglass

import android.content.pm.PackageManager
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.GLES20
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LiquidGlassPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private var activity: android.app.Activity? = null

    companion object {
        private var cachedCapabilities: Map<String, Any>? = null
        // NativeGlassPlatformView registers itself here on init and removes itself on dispose
        internal val activeViews = mutableMapOf<Int, NativeGlassPlatformView>()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "liquid_glass")
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "liquid-glass-native-view",
            NativeGlassViewFactory { activity }
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getDeviceCapabilities" -> {
                cachedCapabilities?.let {
                    result.success(it)
                    return
                }

                val context = flutterPluginBinding.applicationContext
                val pm = context.packageManager
                val features = pm.getSystemAvailableFeatures()

                var vulkanLevel = -1
                var vulkanVersion = 0
                for (feature in features) {
                    when (feature.name) {
                        PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL -> vulkanLevel = feature.version
                        PackageManager.FEATURE_VULKAN_HARDWARE_VERSION -> vulkanVersion = feature.version
                    }
                }

                val apiLevel = android.os.Build.VERSION.SDK_INT

                val gpuRenderer = getGpuRenderer()

                val supportsVulkan = vulkanLevel >= 1 && vulkanVersion >= 0x401000

                val capabilities = mapOf(
                    "vulkanLevel" to vulkanLevel,
                    "vulkanVersion" to vulkanVersion,
                    "apiLevel" to apiLevel,
                    "gpuRenderer" to gpuRenderer,
                    "supportsVulkan" to supportsVulkan
                )

                cachedCapabilities = capabilities
                result.success(capabilities)
            }
            "updateGlassView" -> {
                val viewId = call.argument<Int>("viewId")
                val params = call.argument<Map<String?, Any?>>("params")
                if (viewId != null && params != null) {
                    activeViews[viewId]?.updateParams(params)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "viewId and params required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getGpuRenderer(): String {
        return try {
            val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
            val versionMajor = IntArray(1)
            val versionMinor = IntArray(1)
            EGL14.eglInitialize(display, versionMajor, 0, versionMinor, 0)

            val attribList = intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT,
                EGL14.EGL_NONE
            )
            val configs = arrayOfNulls<EGLConfig>(1)
            val numConfigs = IntArray(1)
            EGL14.eglChooseConfig(display, attribList, 0, configs, 0, 1, numConfigs, 0)

            val pbufferAttribs = intArrayOf(
                EGL14.EGL_WIDTH, 1,
                EGL14.EGL_HEIGHT, 1,
                EGL14.EGL_NONE
            )
            val surface = EGL14.eglCreatePbufferSurface(display, configs[0], pbufferAttribs, 0)

            val contextAttribs = intArrayOf(
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL14.EGL_NONE
            )
            val eglContext = EGL14.eglCreateContext(display, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0)

            EGL14.eglMakeCurrent(display, surface, surface, eglContext)

            val renderer = GLES20.glGetString(GLES20.GL_RENDERER) ?: "unknown"

            EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            EGL14.eglDestroySurface(display, surface)
            EGL14.eglDestroyContext(display, eglContext)
            EGL14.eglTerminate(display)

            renderer
        } catch (e: Exception) {
            "unknown"
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
