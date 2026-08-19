package com.appsflyer.appsflyersdk

import android.util.Log
import androidx.annotation.VisibleForTesting

/**
 * Upper bound for events buffered while no [AppsFlyerEventSink] is attached.
 *
 * The buffer is process-scoped and deliberately survives engine teardown, so it needs a bound:
 * an app that never re-subscribes would otherwise grow it for the lifetime of the process. A
 * session buffers a handful of events, so the cap only acts as a safety valve.
 */
private const val MAX_PENDING_EVENTS = 64

/** Result of attempting to deliver one buffered event through an [AppsFlyerEventSink]. */
internal enum class EventSendResult {
    /** The sink accepted the event; remove it from the head of the buffer. */
    DELIVERED,

    /**
     * The sink cannot take events right now but the event itself is fine — keep it buffered for
     * the next attach (for example while this engine is tearing down).
     */
    RETRY_LATER,

    /** The event itself could not be sent; drop it and detach the sink. */
    DROP,
}

/**
 * Destination for native event JSON on its way to the Dart `af-events` stream.
 */
internal fun interface AppsFlyerEventSink {
    fun send(eventJson: String): EventSendResult
}

/**
 * Process-scoped relay between native SDK events and the Dart `af-events` stream.
 *
 * Android destroys the Flutter engine when the Activity goes away (back press, for example) and
 * builds a new [AppsflyerSdkPlugin] when the app returns, while the native SDK keeps the listener
 * registered by the previous `AppsFlyerRpcHandler`: `subscribeForDeepLink`,
 * `registerConversionListener` and `registerSessionReadyListener` all overwrite a single
 * reference, and the SDK exposes no unsubscribe for deep links. Holding the buffer and the sink
 * here rather than on the plugin instance keeps two guarantees across that teardown:
 *
 * - an event emitted by a listener still bound to a detached engine reaches the live sink;
 * - an event emitted while no sink is attached is replayed on the next attach instead of landing
 *   in the buffer of an unreachable plugin instance.
 *
 * Delivery is FIFO: events are queued first and flushed in publish order, so a replayed event
 * always precedes one published after it.
 *
 * **Threading**: [publish], [attach], and [detach] synchronize the buffer and sink reference so
 * concurrent callers cannot corrupt internal state. They do not hop threads: [drain] invokes
 * [AppsFlyerEventSink.send] on the caller's thread, and the production sink calls
 * [io.flutter.plugin.common.EventChannel.EventSink.success], which must run on the Android main
 * thread. [AppsflyerSdkPlugin] therefore posts [publish] onto the main looper from
 * [AppsflyerSdkPlugin.rpcEventNotifier], and [attach]/[detach] run from [onListen]/[onCancel] on
 * the platform thread. Do not call [publish] or [attach] with a production sink directly from a
 * background thread.
 */
internal object AppsFlyerEventBus {

    private val lock = Any()
    private val pendingEvents = ArrayDeque<String>()

    private var sink: AppsFlyerEventSink? = null

    /** Queues [eventJson], then flushes as much of the buffer as the attached sink accepts. */
    fun publish(eventJson: String) {
        synchronized(lock) {
            pendingEvents.addLast(eventJson)
            var dropped = 0
            while (pendingEvents.size > MAX_PENDING_EVENTS) {
                pendingEvents.removeFirst()
                dropped++
            }
            if (dropped > 0) {
                Log.w(
                    AF_PLUGIN_TAG,
                    "AppsFlyerEventBus dropped $dropped oldest pending event(s); " +
                        "buffer cap is $MAX_PENDING_EVENTS"
                )
            }
            drain()
        }
    }

    /**
     * Makes [sink] the active destination and replays everything buffered so far.
     *
     * The newest attach wins: when a new engine subscribes before the previous one detaches, the
     * newer sink is the reachable one.
     */
    fun attach(sink: AppsFlyerEventSink) {
        synchronized(lock) {
            this.sink = sink
            drain()
        }
    }

    /**
     * Drops [sink] if it is still the active one, leaving the buffer intact.
     *
     * The identity check matters because teardown is not ordered against setup: an engine being
     * detached must not unbind the sink a newer engine has already attached.
     */
    fun detach(sink: AppsFlyerEventSink) {
        synchronized(lock) {
            if (this.sink === sink) {
                this.sink = null
            }
        }
    }

    private fun drain() {
        val target = sink ?: return
        while (pendingEvents.isNotEmpty()) {
            when (target.send(pendingEvents.first())) {
                EventSendResult.DELIVERED -> pendingEvents.removeFirst()
                EventSendResult.RETRY_LATER -> {
                    sink = null
                    return
                }
                EventSendResult.DROP -> {
                    pendingEvents.removeFirst()
                    sink = null
                    return
                }
            }
        }
    }

    @VisibleForTesting
    internal fun pendingCount(): Int = synchronized(lock) { pendingEvents.size }

    @VisibleForTesting
    internal fun reset() {
        synchronized(lock) {
            sink = null
            pendingEvents.clear()
        }
    }
}
