package com.liquidglass

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Outline
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.widget.FrameLayout
import eightbitlab.com.blurview.BlurView
import io.flutter.plugin.platform.PlatformView
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

class NativeGlassPlatformView(
    private val context: Context,
    private val viewId: Int,
    creationParams: Map<String?, Any?>?,
    private val activity: Activity?
) : PlatformView {

    private val root: FrameLayout = FrameLayout(context)
    private val blurView: BlurView = BlurView(context)
    private val overlayView: GlassOverlayView

    private var blurSigma: Double = 12.0
    private var lightAngle: Double = 0.8
    private var lightIntensity: Double = 1.2
    private var specularPower: Double = 14.0
    private var specularKickPower: Double = 20.0
    private var specularKickIntensity: Double = 0.4
    private var lightBandOffset: Double = 10.0
    private var lightBandWidth: Double = 30.0
    private var lightBandStrength: Double = 0.6
    private var tintColor: Int? = null
    private var cornerRadius: Double = 20.0
    private var variant: String = "regular"

    init {
        parseParams(creationParams)

        val density = context.resources.displayMetrics.density
        val cornerRadiusPx = (cornerRadius * density).toFloat()

        root.outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(view: View, outline: Outline) {
                outline.setRoundRect(0, 0, view.width, view.height, cornerRadiusPx)
            }
        }
        root.clipToOutline = true

        val rootView = activity?.window?.decorView?.rootView as? ViewGroup
        if (rootView != null) {
            blurView.setupWith(rootView)
                .setBlurRadius(blurSigma.toFloat().coerceIn(1f, 25f))
        }
        root.addView(
            blurView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        overlayView = GlassOverlayView(context)
        root.addView(
            overlayView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
    }

    private fun parseParams(params: Map<String?, Any?>?) {
        if (params == null) return
        blurSigma = (params["blurSigma"] as? Number)?.toDouble() ?: blurSigma
        lightAngle = (params["lightAngle"] as? Number)?.toDouble() ?: lightAngle
        lightIntensity = (params["lightIntensity"] as? Number)?.toDouble() ?: lightIntensity
        specularPower = (params["specularPower"] as? Number)?.toDouble() ?: specularPower
        specularKickPower = (params["specularKickPower"] as? Number)?.toDouble() ?: specularKickPower
        specularKickIntensity = (params["specularKickIntensity"] as? Number)?.toDouble() ?: specularKickIntensity
        lightBandOffset = (params["lightBandOffset"] as? Number)?.toDouble() ?: lightBandOffset
        lightBandWidth = (params["lightBandWidth"] as? Number)?.toDouble() ?: lightBandWidth
        lightBandStrength = (params["lightBandStrength"] as? Number)?.toDouble() ?: lightBandStrength
        tintColor = (params["tintColor"] as? Number)?.toInt()
        cornerRadius = (params["cornerRadius"] as? Number)?.toDouble() ?: cornerRadius
        variant = (params["variant"] as? String) ?: variant
    }

    fun updateParams(params: Map<String?, Any?>) {
        parseParams(params)
        blurView.setBlurRadius(blurSigma.toFloat().coerceIn(1f, 25f))
        overlayView.invalidate()
    }

    override fun getView(): View = root

    override fun dispose() {
    }

    inner class GlassOverlayView(context: Context) : View(context) {

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            if (w <= 0f || h <= 0f) return

            val density = resources.displayMetrics.density
            val cornerRadiusPx = (cornerRadius * density).toFloat()
            val rect = RectF(0f, 0f, w, h)

            val isClear = variant == "clear"
            val variantAlphaMultiplier = if (isClear) 0.55f else 1.0f

            // Tint layer (skipped for clear variant)
            if (!isClear) {
                val argb = tintColor ?: 0x08F5E6D3
                paint.reset()
                paint.color = argb
                paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
                canvas.drawRoundRect(rect, cornerRadiusPx, cornerRadiusPx, paint)
                paint.xfermode = null
            }

            // Primary specular highlight
            val dx = cos(lightAngle).toFloat()
            val dy = sin(lightAngle).toFloat()
            val primaryAlpha = (lightIntensity.coerceIn(0.0, 3.0) / 3.0 * 255.0 * variantAlphaMultiplier).toInt()
            val specularTightness = (specularPower / 200.0).toFloat().coerceIn(0.05f, 0.5f)
            val midLow = 0.5f - specularTightness
            val midHigh = 0.5f + specularTightness
            val primaryGradient = LinearGradient(
                w / 2f - dx * w / 2f,
                h / 2f - dy * h / 2f,
                w / 2f + dx * w / 2f,
                h / 2f + dy * h / 2f,
                intArrayOf(
                    Color.TRANSPARENT,
                    Color.argb(primaryAlpha, 255, 255, 255),
                    Color.TRANSPARENT
                ),
                floatArrayOf(midLow, 0.5f, midHigh),
                Shader.TileMode.CLAMP
            )
            paint.reset()
            paint.shader = primaryGradient
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.ADD)
            canvas.drawRoundRect(rect, cornerRadiusPx, cornerRadiusPx, paint)
            paint.xfermode = null
            paint.shader = null

            // Kick specular (opposite direction)
            val kickAngle = lightAngle + PI
            val kdx = cos(kickAngle).toFloat()
            val kdy = sin(kickAngle).toFloat()
            val kickAlpha = (specularKickIntensity.coerceIn(0.0, 1.0) * 255.0 * variantAlphaMultiplier).toInt()
            val kickTightness = (specularKickPower / 200.0).toFloat().coerceIn(0.05f, 0.5f)
            val kickMidLow = 0.5f - kickTightness
            val kickMidHigh = 0.5f + kickTightness
            val kickGradient = LinearGradient(
                w / 2f - kdx * w / 2f,
                h / 2f - kdy * h / 2f,
                w / 2f + kdx * w / 2f,
                h / 2f + kdy * h / 2f,
                intArrayOf(
                    Color.TRANSPARENT,
                    Color.argb(kickAlpha, 255, 255, 255),
                    Color.TRANSPARENT
                ),
                floatArrayOf(kickMidLow, 0.5f, kickMidHigh),
                Shader.TileMode.CLAMP
            )
            paint.reset()
            paint.shader = kickGradient
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.ADD)
            canvas.drawRoundRect(rect, cornerRadiusPx, cornerRadiusPx, paint)
            paint.xfermode = null
            paint.shader = null

            // Fresnel rim using RadialGradient with stroke
            val cx = w / 2f
            val cy = h / 2f
            val rimRadius = min(w, h) / 2f
            val rimAlpha = (180 * variantAlphaMultiplier).toInt()
            val fresnelGradient = RadialGradient(
                cx, cy, rimRadius,
                intArrayOf(Color.TRANSPARENT, Color.argb(rimAlpha, 255, 255, 255)),
                floatArrayOf(0.0f, 1.0f),
                Shader.TileMode.CLAMP
            )
            paint.reset()
            paint.shader = fresnelGradient
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = cornerRadiusPx * 0.6f
            canvas.drawRoundRect(rect, cornerRadiusPx, cornerRadiusPx, paint)
            paint.style = Paint.Style.FILL
            paint.shader = null

            // Light band (inner glow stroke)
            val bandOffsetPx = (lightBandOffset * density).toFloat()
            val bandWidthPx = (lightBandWidth * density).toFloat()
            val bandAlpha = (lightBandStrength * 0.3 * 255 * variantAlphaMultiplier).toInt()
            val bandRect = RectF(
                bandOffsetPx,
                bandOffsetPx,
                w - bandOffsetPx,
                h - bandOffsetPx
            )
            val bandCornerRadius = (cornerRadiusPx - bandOffsetPx).coerceAtLeast(0f)
            paint.reset()
            paint.color = Color.argb(bandAlpha, 255, 255, 255)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = bandWidthPx
            canvas.drawRoundRect(bandRect, bandCornerRadius, bandCornerRadius, paint)
            paint.style = Paint.Style.FILL
        }
    }
}
