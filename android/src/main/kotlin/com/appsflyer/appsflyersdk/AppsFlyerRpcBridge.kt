package com.appsflyer.appsflyersdk

import androidx.annotation.VisibleForTesting

import com.appsflyer.pluginbridge.model.RpcResponse

/**
 * Native-facing half of the bridge: turns an RPC request envelope into a response.
 *
 * Implemented over `AppsFlyerRpcHandler`. Keeping the plugin behind this interface is what lets
 * [AppsFlyerRpcBridge] own the handler without every caller depending on how it is built.
 */
internal fun interface AppsFlyerRpcExecutor {
    fun execute(requestJson: String): RpcResponse
}

/**
 * Process-scoped owner of the native-facing RPC executor.
 *
 * `AppsFlyerLib` is a process-wide singleton: once initialized it keeps its configuration and the
 * listeners registered through `AppsFlyerRpcHandler` for as long as the process lives. Android
 * destroys the Flutter engine well before that (back press, a Flutter fragment leaving an
 * add-to-app host) and builds a new [AppsflyerSdkPlugin] when the app returns, so an executor held
 * on the plugin instance would be rebuilt against an SDK that is already configured — with no
 * memory of the listeners it registered there.
 *
 * Holding it here keeps one executor per process, so a new engine reattaches to the configured
 * bridge instead of deriving it again. What stays engine-scoped is the Dart-facing half: the
 * channels and the `EventChannel.EventSink` are only valid for the engine that created them and
 * are released in `onDetachedFromEngine`.
 *
 * This does not carry Dart state across the gap. The application's callbacks lived in the
 * destroyed isolate, so it still has to call the `register*Listener` APIs again after
 * a new engine attaches; reusing the executor only makes that re-registration
 * reuse the existing listeners instead of building new ones.
 *
 * **Threading**: creation is synchronized, so concurrent engines resolve to the same executor.
 */
internal object AppsFlyerRpcBridge {

    private val lock = Any()

    private var executor: AppsFlyerRpcExecutor? = null

    /** Returns the process-wide executor, creating it with [create] on first use. */
    fun shared(create: () -> AppsFlyerRpcExecutor): AppsFlyerRpcExecutor {
        synchronized(lock) {
            return executor ?: create().also { executor = it }
        }
    }

    @VisibleForTesting
    internal fun reset() {
        synchronized(lock) {
            executor = null
        }
    }
}
