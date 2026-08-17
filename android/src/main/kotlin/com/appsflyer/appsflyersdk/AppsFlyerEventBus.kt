package com.appsflyer.appsflyersdk

import androidx.annotation.VisibleForTesting

/**
 * Upper bound for events buffered while no [AppsFlyerEventSink] is attached.
 *
 * The buffer is process-scoped and deliberately survives engine teardown, so it needs a bound:
 * an app that never re-subscribes would otherwise grow it for the lifetime of the process. A
 * session buffers a handful of events, so the cap only acts as a safety valve.
 */
private const val MAX_PENDING_EVENTS = 64

/**
 * Destination for native event JSON on its way to the Dart `af-events` stream.
 *
 * [send] returns `false` when this sink refuses an event. The bus drops that event, detaches the
 * sink, and leaves the rest of the buffer for the next attach.
 */
internal fun interface AppsFlyerEventSink {
    fun send(eventJson: String): Boolean
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
 *   in the buffer of an unreachable plugin instance (RD-65582).
 *
 * Delivery is FIFO: events are queued first and flushed in publish order, so a replayed event
 * always precedes one published after it.
 *
 * **Threading**: every entry point is synchronized, so publishing from an SDK callback thread is
 * safe. Delivery runs on the caller's thread and `EventChannel.EventSink` may only be used on the
 * platform main thread, so callers publish from there — see [AppsflyerSdkPlugin].
 */
internal object AppsFlyerEventBus {

    private val lock = Any()
    private val pendingEvents = ArrayDeque<String>()

    private var sink: AppsFlyerEventSink? = null

    /** Queues [eventJson], then flushes as much of the buffer as the attached sink accepts. */
    fun publish(eventJson: String) {
        synchronized(lock) {
            pendingEvents.addLast(eventJson)
            while (pendingEvents.size > MAX_PENDING_EVENTS) {
                pendingEvents.removeFirst()
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
            val event = pendingEvents.first()
            if (target.send(event)) {
                pendingEvents.removeFirst()
                continue
            }
            pendingEvents.removeFirst()
            sink = null
            return
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
