package com.raffazatyan.mail_to

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android side of `mail_to`.
 *
 * Unlike iOS, apps that handle `mailto:` can be enumerated, so the list comes
 * straight from [PackageManager] instead of a hardcoded table. Android 11+
 * package visibility is satisfied by the `<queries>` block this plugin's own
 * manifest contributes — host apps need no manifest change.
 */
class MailToPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "mail_to")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "installedApps" -> result.success(installedApps().map(::encode))
            "compose" -> compose(call, result)
            "pickApp" -> pickApp(call, result)
            "share" -> share(call, result)
            else -> result.notImplemented()
        }
    }

    // region Detection

    private data class MailApp(
        val id: String,
        val name: String,
        val icon: android.graphics.drawable.Drawable?,
    )

    private fun installedApps(): List<MailApp> {
        val packageManager = context.packageManager
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))

        return packageManager
            .queryIntentActivities(intent, 0)
            .map { resolveInfo: ResolveInfo ->
                MailApp(
                    id = resolveInfo.activityInfo.packageName,
                    name = resolveInfo.loadLabel(packageManager).toString(),
                    icon = runCatching { resolveInfo.loadIcon(packageManager) }.getOrNull(),
                )
            }
            .distinctBy { it.id }
            .sortedBy { it.name.lowercase() }
    }

    private fun encode(app: MailApp): Map<String, Any> =
        mapOf("id" to app.id, "name" to app.name, "usesNativeComposer" to false)

    // endregion

    // region Compose

    private fun compose(call: MethodCall, result: Result) {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")).apply {
            call.argument<List<String>>("to")?.takeIf { it.isNotEmpty() }?.let {
                putExtra(Intent.EXTRA_EMAIL, it.toTypedArray())
            }
            call.argument<List<String>>("cc")?.takeIf { it.isNotEmpty() }?.let {
                putExtra(Intent.EXTRA_CC, it.toTypedArray())
            }
            call.argument<List<String>>("bcc")?.takeIf { it.isNotEmpty() }?.let {
                putExtra(Intent.EXTRA_BCC, it.toTypedArray())
            }
            putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject") ?: "")
            putExtra(Intent.EXTRA_TEXT, call.argument<String>("body") ?: "")

            // Target the chosen app directly; without it the system chooser
            // appears, which is what the caller asked us to replace.
            call.argument<String>("appId")?.let { setPackage(it) }
        }

        val launcher = activity ?: context
        if (launcher === context) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            launcher.startActivity(intent)
            result.success(true)
        } catch (e: android.content.ActivityNotFoundException) {
            result.success(false)
        }
    }

    // endregion

    // region Picker

    /**
     * Centred dialog with each app's launcher icon and label, mirroring the
     * iOS `.alert` picker.
     *
     * With no mail app installed the same dialog shows the "no mail app"
     * message, so callers need no branch of their own.
     */
    private fun pickApp(call: MethodCall, result: Result) {
        val currentActivity = activity
        val apps = installedApps()
        if (currentActivity == null) {
            result.success(null)
            return
        }

        if (apps.isEmpty() && call.argument<Boolean>("showEmptyAlert") == false) {
            result.success(null)
            return
        }

        MailAppPickerDialog.show(
            activity = currentActivity,
            title = call.argument<String>("title") ?: "Choose a mail app",
            rows = apps.map { MailAppRow(label = it.name, icon = it.icon) },
            emptyMessage = call.argument<String>("emptyMessage")
                ?: "No mail app is installed on this device.",
            okLabel = call.argument<String>("okLabel") ?: "OK",
            // null hides the entry entirely.
            otherAppsLabel = if (call.argument<Boolean>("showOtherApps") != false) {
                call.argument<String>("otherAppsLabel") ?: "Other apps…"
            } else {
                null
            },
            onPicked = { index ->
                result.success(index?.let { encode(apps[it]) })
            },
            onOtherApps = { result.success(OTHER_APPS_ENTRY) },
        )
    }

    // endregion

    // region Share sheet

    /** System chooser over `ACTION_SEND` — every app that takes text. */
    private fun share(call: MethodCall, result: Result) {
        val subject = call.argument<String>("subject") ?: ""
        @Suppress("UNCHECKED_CAST")
        val metadata = call.argument<Map<String, Any?>>("metadata")

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, call.argument<String>("body") ?: "")
            // Chooser preview headline. Android has no equivalent of the iOS
            // subtitle or icon slot for a plain text share.
            putExtra(
                Intent.EXTRA_TITLE,
                (metadata?.get("title") as? String)?.takeIf { it.isNotEmpty() } ?: subject,
            )
        }

        val launcher = activity ?: context
        val chooser = Intent.createChooser(intent, null).apply {
            if (launcher === context) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            launcher.startActivity(chooser)
            result.success(true)
        } catch (e: android.content.ActivityNotFoundException) {
            result.success(false)
        }
    }

    private companion object {
        val OTHER_APPS_ENTRY = mapOf(
            "id" to "__other_apps__",
            "name" to "Other apps",
            "usesNativeComposer" to false,
            "isOther" to true,
        )
    }

    // endregion
}
