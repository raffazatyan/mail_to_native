package com.raffazatyan.mail_to

import android.app.Activity
import android.app.Dialog
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** One row of the picker. */
internal data class MailAppRow(val label: String, val icon: Drawable?)

/**
 * Bottom sheet listing the installed mail apps — icon plus label, one tap to
 * pick. With an empty list it renders the "no mail app" message instead.
 *
 * Built programmatically on a plain [Dialog] rather than `BottomSheetDialog` /
 * `MaterialAlertDialogBuilder`: those require the host activity to carry an
 * AppCompat or Material theme, which a Flutter app is not required to have.
 * This looks the same regardless of the host theme and adds no dependency.
 */
internal object MailAppPickerSheet {

    private const val CORNER_RADIUS_DP = 28f
    private const val HANDLE_WIDTH_DP = 32f
    private const val HANDLE_HEIGHT_DP = 4f
    private const val ICON_SIZE_DP = 40f
    private const val ROW_HEIGHT_DP = 64f
    private const val SIDE_PADDING_DP = 20f
    private const val MAX_HEIGHT_RATIO = 0.7f

    private class Palette(
        val surface: Int,
        val onSurface: Int,
        val onSurfaceVariant: Int,
        val handle: Int,
        val ripple: Int,
    )

    /**
     * @param onPicked the tapped index, or `null` when dismissed. Called once.
     */
    fun show(
        activity: Activity,
        title: String,
        rows: List<MailAppRow>,
        emptyMessage: String,
        onPicked: (Int?) -> Unit,
    ) {
        val palette = palette(activity)
        var answered = false
        fun answer(index: Int?) {
            if (answered) return
            answered = true
            onPicked(index)
        }

        val dialog = Dialog(activity)
        val content = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = sheetBackground(activity, palette)
            setPadding(0, activity.dpInt(12f), 0, activity.dpInt(8f))
            addView(handle(activity, palette))
            addView(titleView(activity, palette, title))
            addView(
                if (rows.isEmpty()) {
                    emptyView(activity, palette, emptyMessage)
                } else {
                    appList(activity, palette, rows) { index ->
                        answer(index)
                        dialog.dismiss()
                    }
                },
            )
        }

        dialog.apply {
            requestWindowFeature(Window.FEATURE_NO_TITLE)
            setContentView(
                content,
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ),
            )
            setCanceledOnTouchOutside(true)
            // Covers every close path — back press, scrim tap, row tap.
            setOnDismissListener { answer(null) }
            window?.apply {
                setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                setLayout(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                )
                setGravity(Gravity.BOTTOM)
                setWindowAnimations(android.R.style.Animation_InputMethod)
            }
            show()
        }
    }

    private fun palette(activity: Activity): Palette {
        val isDark =
            (activity.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        return if (isDark) {
            Palette(
                surface = Color.parseColor("#1C1B1F"),
                onSurface = Color.parseColor("#E6E1E5"),
                onSurfaceVariant = Color.parseColor("#CAC4D0"),
                handle = Color.parseColor("#49454F"),
                ripple = Color.parseColor("#33FFFFFF"),
            )
        } else {
            Palette(
                surface = Color.parseColor("#FFFBFE"),
                onSurface = Color.parseColor("#1C1B1F"),
                onSurfaceVariant = Color.parseColor("#49454F"),
                handle = Color.parseColor("#CAC4D0"),
                ripple = Color.parseColor("#1F000000"),
            )
        }
    }

    /** Rounded on top only — the sheet sits on the screen edge. */
    private fun sheetBackground(activity: Activity, palette: Palette): Drawable =
        GradientDrawable().apply {
            setColor(palette.surface)
            val radius = activity.dp(CORNER_RADIUS_DP)
            cornerRadii = floatArrayOf(radius, radius, radius, radius, 0f, 0f, 0f, 0f)
        }

    private fun handle(activity: Activity, palette: Palette): View =
        View(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                activity.dpInt(HANDLE_WIDTH_DP),
                activity.dpInt(HANDLE_HEIGHT_DP),
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = activity.dpInt(12f)
            }
            background = GradientDrawable().apply {
                setColor(palette.handle)
                cornerRadius = activity.dp(HANDLE_HEIGHT_DP / 2f)
            }
        }

    private fun titleView(activity: Activity, palette: Palette, title: String): TextView =
        TextView(activity).apply {
            text = title
            setTextColor(palette.onSurface)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(
                activity.dpInt(SIDE_PADDING_DP),
                activity.dpInt(4f),
                activity.dpInt(SIDE_PADDING_DP),
                activity.dpInt(12f),
            )
        }

    private fun emptyView(activity: Activity, palette: Palette, message: String): TextView =
        TextView(activity).apply {
            text = message
            setTextColor(palette.onSurfaceVariant)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setPadding(
                activity.dpInt(SIDE_PADDING_DP),
                0,
                activity.dpInt(SIDE_PADDING_DP),
                activity.dpInt(24f),
            )
        }

    /** Scrolls internally so a long list cannot push the sheet off-screen. */
    private fun appList(
        activity: Activity,
        palette: Palette,
        rows: List<MailAppRow>,
        onRow: (Int) -> Unit,
    ): View {
        val list = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            rows.forEachIndexed { index, row ->
                addView(
                    row(activity, palette, row).apply {
                        setOnClickListener { onRow(index) }
                    },
                )
            }
        }

        val maxHeight =
            (activity.resources.displayMetrics.heightPixels * MAX_HEIGHT_RATIO).toInt()

        return object : ScrollView(activity) {
            override fun onMeasure(widthSpec: Int, heightSpec: Int) {
                super.onMeasure(
                    widthSpec,
                    MeasureSpec.makeMeasureSpec(maxHeight, MeasureSpec.AT_MOST),
                )
            }
        }.apply {
            isVerticalScrollBarEnabled = false
            addView(list)
        }
    }

    private fun row(activity: Activity, palette: Palette, row: MailAppRow): View =
        LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            isClickable = true
            isFocusable = true
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                activity.dpInt(ROW_HEIGHT_DP),
            )
            setPadding(activity.dpInt(SIDE_PADDING_DP), 0, activity.dpInt(SIDE_PADDING_DP), 0)
            background = RippleDrawable(
                ColorStateList.valueOf(palette.ripple),
                null,
                ColorDrawable(Color.WHITE),
            )

            row.icon?.let { icon ->
                addView(
                    ImageView(activity).apply {
                        setImageDrawable(icon)
                        layoutParams = LinearLayout.LayoutParams(
                            activity.dpInt(ICON_SIZE_DP),
                            activity.dpInt(ICON_SIZE_DP),
                        ).apply { marginEnd = activity.dpInt(16f) }
                    },
                )
            }

            addView(
                TextView(activity).apply {
                    text = row.label
                    setTextColor(palette.onSurface)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                },
            )
        }

    private fun Activity.dp(value: Float): Float = value * resources.displayMetrics.density

    private fun Activity.dpInt(value: Float): Int = dp(value).toInt()
}
