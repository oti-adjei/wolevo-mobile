package com.wolevo.wolevo

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Alternate app icons.
 *
 * Android has no equivalent of iOS's setAlternateIconName. An icon swap is done
 * by enabling one <activity-alias> and disabling the others, which is why
 * MainActivity itself carries no LAUNCHER intent-filter — even the default icon
 * is an alias, so all of them toggle the same way.
 *
 * Written here rather than pulled from a plugin: the pub packages that do this
 * are CocoaPods-only on the iOS side, and this project builds with Swift
 * Package Manager.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "wolevo/app_icon"

    private val aliases = listOf(
        "MainActivityAliasDefault",
        "MainActivityAliasLime",
        "MainActivityAliasMidnight",
        "MainActivityAliasFestive",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportsAlternateIcons" -> result.success(true)

                    "setAlternateIcon" -> {
                        val name = call.argument<String>("name")
                            ?: aliases.first()
                        try {
                            setIcon(name)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("icon_failed", e.message, null)
                        }
                    }

                    "currentIcon" -> result.success(currentAlias())

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Enables [target] and disables every other alias. Exactly one must be
     * enabled or the app shows twice in the launcher.
     *
     * DONT_KILL_APP keeps the process alive; some launchers still take a moment
     * to redraw, and a few cache the old icon until reboot.
     */
    private fun setIcon(target: String) {
        aliases.forEach { alias ->
            val state = if (alias == target) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.$alias"),
                state,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun currentAlias(): String? = aliases.firstOrNull { alias ->
        packageManager.getComponentEnabledSetting(
            ComponentName(packageName, "$packageName.$alias"),
        ) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
    }
}
