package com.appsflyer.appsflyersdk

import android.app.Activity
import android.content.Context

import androidx.annotation.VisibleForTesting

/**
 * Process-scoped source of the Android context handed to `AppsFlyerRpcHandler`.
 *
 * The handler takes a `contextProvider: () -> Context` and resolves a lazy `applicationContext`
 * for most SDK calls, invoking the provider directly only where an `Activity` is required (`init`,
 * `collectDataFromLauncherActivity`). That seam is why one process-wide handler can serve both:
 * it reads the currently attached Activity at call time instead of being built around one context.
 *
 * The provider lambda must therefore capture this object and nothing else. Capturing an
 * [AppsflyerSdkPlugin] instance would pin a plugin that Android destroys on every engine teardown,
 * and capturing an [Activity] would pin it for the lifetime of the process.
 *
 * The application context is set once and never cleared; it outlives every engine. Activities are
 * tracked per attaching plugin so that a destroyed one is never retained and, just as importantly,
 * so that one engine detaching cannot drop an Activity another engine is still attached to.
 */
internal object AppsFlyerContextHolder {

    private val lock = Any()

    @Volatile
    private var appContext: Context? = null

    /**
     * Attached Activities keyed by the plugin instance that attached them, in attach order.
     *
     * A single slot would be wrong in an add-to-app host: two engines can attach to the same
     * Activity, and the first one to detach would clear it while the second is still running. Keying
     * by owner means each engine only ever removes its own entry.
     *
     * Entries are removed on both `onDetachedFromActivity` and `onDetachedFromEngine`, so a missed
     * callback on one path is still covered by the other.
     */
    private val attachments = LinkedHashMap<Any, Activity>()

    /**
     * The context for the next handler call: the most recently attached Activity when there is one,
     * otherwise the application context.
     *
     * Most recent wins because that is the Activity the user is currently in, which is the one whose
     * intent `init` and `collectDataFromLauncherActivity` are meant to read.
     */
    fun current(): Context = synchronized(lock) {
        attachments.values.lastOrNull()
            ?: appContext
            ?: throw IllegalStateException("Plugin is not attached to a Flutter engine")
    }

    /** Whether a context is available, i.e. the plugin has attached to an engine at least once. */
    fun hasContext(): Boolean = synchronized(lock) {
        attachments.isNotEmpty() || appContext != null
    }

    /** [context] must already be an application context — Flutter's plugin binding supplies one. */
    fun setAppContext(context: Context) {
        appContext = context
    }

    /** [owner] is the attaching [AppsflyerSdkPlugin] instance, used only as an identity key. */
    fun attachActivity(owner: Any, activity: Activity) {
        synchronized(lock) {
            // Removed first so a reattach after a configuration change moves the entry to the end
            // and becomes the most recent one again.
            attachments.remove(owner)
            attachments[owner] = activity
        }
    }

    fun detachActivity(owner: Any) {
        synchronized(lock) {
            attachments.remove(owner)
        }
    }

    @VisibleForTesting
    internal fun reset() {
        synchronized(lock) {
            appContext = null
            attachments.clear()
        }
    }
}
