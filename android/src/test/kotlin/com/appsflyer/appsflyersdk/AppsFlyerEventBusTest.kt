package com.appsflyer.appsflyersdk

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Records every delivery attempt and accepts at most [acceptLimit] of them.
 *
 * An unlimited sink stands in for a live engine; a limited one for an engine that goes away while
 * the buffer is being flushed.
 */
private class RecordingSink(private val acceptLimit: Int = Int.MAX_VALUE) : AppsFlyerEventSink {

    val received: MutableList<String> = Collections.synchronizedList(mutableListOf())

    override fun send(eventJson: String): Boolean {
        received += eventJson
        return received.size <= acceptLimit
    }
}

class AppsFlyerEventBusTest {

    @Before
    fun setUp() = AppsFlyerEventBus.reset()

    @After
    fun tearDown() = AppsFlyerEventBus.reset()

    // region delivery to an attached sink

    @Test
    fun publish_withAttachedSink_deliversImmediately() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)

        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(listOf(EVENT_A), sink.received)
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun publish_withAttachedSink_preservesPublishOrder() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)

        AppsFlyerEventBus.publish(EVENT_A)
        AppsFlyerEventBus.publish(EVENT_B)
        AppsFlyerEventBus.publish(EVENT_C)

        assertEquals(listOf(EVENT_A, EVENT_B, EVENT_C), sink.received)
    }

    @Test
    fun attach_withEmptyBuffer_deliversNothing() {
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)

        assertEquals(emptyList<String>(), sink.received)
    }

    // endregion

    // region buffering and replay

    @Test
    fun publish_withoutSink_buffersInsteadOfDropping() {
        AppsFlyerEventBus.publish(EVENT_A)
        AppsFlyerEventBus.publish(EVENT_B)

        assertEquals(2, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun attach_afterBufferedPublish_replaysInPublishOrder() {
        AppsFlyerEventBus.publish(EVENT_A)
        AppsFlyerEventBus.publish(EVENT_B)
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)

        assertEquals(listOf(EVENT_A, EVENT_B), sink.received)
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun publish_afterReplay_keepsReplayedEventsBeforeLiveOnes() {
        AppsFlyerEventBus.publish(EVENT_A)
        AppsFlyerEventBus.publish(EVENT_B)
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)
        AppsFlyerEventBus.publish(EVENT_C)

        assertEquals(listOf(EVENT_A, EVENT_B, EVENT_C), sink.received)
    }

    @Test
    fun attach_twiceWithoutNewEvents_doesNotRedeliver() {
        AppsFlyerEventBus.publish(EVENT_A)
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)
        AppsFlyerEventBus.attach(sink)

        assertEquals(listOf(EVENT_A), sink.received)
    }

    // endregion

    // region engine lifecycle

    @Test
    fun publish_afterDetach_isBufferedForTheNextEngine() {
        val firstEngineSink = RecordingSink()
        AppsFlyerEventBus.attach(firstEngineSink)
        AppsFlyerEventBus.detach(firstEngineSink)

        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(emptyList<String>(), firstEngineSink.received)
        assertEquals(1, AppsFlyerEventBus.pendingCount())
    }

    /** The regression this class exists for: an event emitted while no engine is attached. */
    @Test
    fun engineRecreation_eventPublishedWhileDetached_reachesTheNewEngine() {
        val firstEngineSink = RecordingSink()
        AppsFlyerEventBus.attach(firstEngineSink)
        AppsFlyerEventBus.detach(firstEngineSink)
        AppsFlyerEventBus.publish(EVENT_A)

        val secondEngineSink = RecordingSink()
        AppsFlyerEventBus.attach(secondEngineSink)

        assertEquals(listOf(EVENT_A), secondEngineSink.received)
        assertEquals(emptyList<String>(), firstEngineSink.received)
    }

    @Test
    fun attach_whileAnotherSinkIsActive_routesToTheNewestSink() {
        val oldSink = RecordingSink()
        val newSink = RecordingSink()
        AppsFlyerEventBus.attach(oldSink)

        AppsFlyerEventBus.attach(newSink)
        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(listOf(EVENT_A), newSink.received)
        assertEquals(emptyList<String>(), oldSink.received)
    }

    /**
     * Engine teardown is not ordered against engine setup, so a detaching engine must not unbind
     * the sink a newer engine already attached.
     */
    @Test
    fun detach_withStaleSink_keepsTheActiveSinkAttached() {
        val staleSink = RecordingSink()
        val activeSink = RecordingSink()
        AppsFlyerEventBus.attach(staleSink)
        AppsFlyerEventBus.attach(activeSink)

        AppsFlyerEventBus.detach(staleSink)
        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(listOf(EVENT_A), activeSink.received)
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun detach_calledTwice_isIdempotent() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)

        AppsFlyerEventBus.detach(sink)
        AppsFlyerEventBus.detach(sink)
        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(emptyList<String>(), sink.received)
        assertEquals(1, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun detach_withNeverAttachedSink_leavesBufferIntact() {
        AppsFlyerEventBus.publish(EVENT_A)

        AppsFlyerEventBus.detach(RecordingSink())

        assertEquals(1, AppsFlyerEventBus.pendingCount())
    }

    // endregion

    // region refusing sinks

    @Test
    fun publish_whenSinkRefuses_keepsEventBufferedAndDropsSink() {
        val refusingSink = RecordingSink(acceptLimit = 0)
        AppsFlyerEventBus.attach(refusingSink)

        AppsFlyerEventBus.publish(EVENT_A)

        assertEquals(listOf(EVENT_A), refusingSink.received)
        assertEquals(1, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun publish_afterSinkRefused_doesNotReachThatSinkAgain() {
        val refusingSink = RecordingSink(acceptLimit = 0)
        AppsFlyerEventBus.attach(refusingSink)
        AppsFlyerEventBus.publish(EVENT_A)

        AppsFlyerEventBus.publish(EVENT_B)

        assertEquals(listOf(EVENT_A), refusingSink.received)
        assertEquals(2, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun attach_afterSinkRefused_replaysEveryUndeliveredEventInOrder() {
        AppsFlyerEventBus.publish(EVENT_A)
        AppsFlyerEventBus.publish(EVENT_B)
        AppsFlyerEventBus.publish(EVENT_C)
        val partialSink = RecordingSink(acceptLimit = 1)

        AppsFlyerEventBus.attach(partialSink)
        val recoveredSink = RecordingSink()
        AppsFlyerEventBus.attach(recoveredSink)

        assertEquals(listOf(EVENT_A, EVENT_B), partialSink.received)
        assertEquals(listOf(EVENT_B, EVENT_C), recoveredSink.received)
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    // endregion

    // region buffer bound

    @Test
    fun publish_beyondBufferBound_keepsTheMostRecentEvents() {
        val overflow = 5
        val published = (0 until MAX_PENDING_EVENTS + overflow).map { index -> "event-$index" }
        published.forEach { event -> AppsFlyerEventBus.publish(event) }
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)

        assertEquals(MAX_PENDING_EVENTS, sink.received.size)
        assertEquals(published.takeLast(MAX_PENDING_EVENTS), sink.received)
    }

    @Test
    fun publish_atBufferBound_dropsNothing() {
        val published = (0 until MAX_PENDING_EVENTS).map { index -> "event-$index" }
        published.forEach { event -> AppsFlyerEventBus.publish(event) }
        val sink = RecordingSink()

        AppsFlyerEventBus.attach(sink)

        assertEquals(published, sink.received)
    }

    // endregion

    // region state hygiene

    @Test
    fun reset_clearsBufferAndSink() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)
        AppsFlyerEventBus.publish(EVENT_A)

        AppsFlyerEventBus.reset()
        AppsFlyerEventBus.publish(EVENT_B)

        assertEquals(listOf(EVENT_A), sink.received)
        assertEquals(1, AppsFlyerEventBus.pendingCount())
    }

    // endregion

    // region concurrency

    /**
     * The notifier hops to the main thread today, but the bus is reachable from a static notifier
     * that any SDK callback thread can drive, so it has to hold under parallel publishing.
     */
    @Test
    fun publish_fromManyThreads_deliversEveryEventExactlyOnce() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)

        publishConcurrently(threads = THREAD_COUNT, eventsPerThread = EVENTS_PER_THREAD)

        val expectedTotal = THREAD_COUNT * EVENTS_PER_THREAD
        assertEquals(expectedTotal, sink.received.size)
        assertEquals(expectedTotal, sink.received.toSet().size)
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun publish_fromManyThreads_preservesPerThreadOrder() {
        val sink = RecordingSink()
        AppsFlyerEventBus.attach(sink)

        publishConcurrently(threads = THREAD_COUNT, eventsPerThread = EVENTS_PER_THREAD)

        for (thread in 0 until THREAD_COUNT) {
            val ownEvents = sink.received.filter { event -> event.startsWith("t$thread-") }
            val expected = (0 until EVENTS_PER_THREAD).map { index -> "t$thread-$index" }
            assertEquals(expected, ownEvents)
        }
    }

    /**
     * Publishing while engines attach and detach must not lose or duplicate events. The event count
     * stays below the buffer bound so that every event is accounted for.
     */
    @Test
    fun publish_whileSinksChurn_losesAndDuplicatesNothing() {
        val deliveries: MutableList<String> = Collections.synchronizedList(mutableListOf())
        val churnThreads = 4
        val eventsPerThread = 8
        val executor = Executors.newFixedThreadPool(churnThreads * 2)
        val startGate = CountDownLatch(1)

        try {
            val publishers = (0 until churnThreads).map { thread ->
                executor.submit {
                    startGate.await()
                    for (index in 0 until eventsPerThread) {
                        AppsFlyerEventBus.publish("t$thread-$index")
                    }
                }
            }
            val churners = (0 until churnThreads).map {
                executor.submit {
                    startGate.await()
                    repeat(eventsPerThread) {
                        val sink = AppsFlyerEventSink { eventJson ->
                            deliveries += eventJson
                            true
                        }
                        AppsFlyerEventBus.attach(sink)
                        AppsFlyerEventBus.detach(sink)
                    }
                }
            }

            startGate.countDown()
            (publishers + churners).forEach { task -> task.get(TASK_TIMEOUT_SECONDS, TimeUnit.SECONDS) }
        } finally {
            executor.shutdownNow()
        }

        val finalSink = RecordingSink()
        AppsFlyerEventBus.attach(finalSink)
        val allDelivered = deliveries + finalSink.received
        val expected = (0 until churnThreads).flatMap { thread ->
            (0 until eventsPerThread).map { index -> "t$thread-$index" }
        }

        assertEquals(expected.size, allDelivered.size)
        assertEquals(expected.toSet(), allDelivered.toSet())
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    @Test
    fun attach_concurrentlyWithPublish_endsWithASingleActiveSink() {
        val executor = Executors.newFixedThreadPool(2)
        val startGate = CountDownLatch(1)
        val lastSink = RecordingSink()

        try {
            val publisher = executor.submit {
                startGate.await()
                repeat(EVENTS_PER_THREAD) { index -> AppsFlyerEventBus.publish("p-$index") }
            }
            val attacher = executor.submit {
                startGate.await()
                repeat(EVENTS_PER_THREAD) { AppsFlyerEventBus.attach(RecordingSink()) }
            }
            startGate.countDown()
            listOf(publisher, attacher).forEach { task -> task.get(TASK_TIMEOUT_SECONDS, TimeUnit.SECONDS) }
        } finally {
            executor.shutdownNow()
        }

        AppsFlyerEventBus.attach(lastSink)
        AppsFlyerEventBus.publish(EVENT_A)

        assertTrue(lastSink.received.contains(EVENT_A))
        assertEquals(0, AppsFlyerEventBus.pendingCount())
    }

    private fun publishConcurrently(threads: Int, eventsPerThread: Int) {
        val executor = Executors.newFixedThreadPool(threads)
        val startGate = CountDownLatch(1)
        try {
            val tasks = (0 until threads).map { thread ->
                executor.submit {
                    startGate.await()
                    for (index in 0 until eventsPerThread) {
                        AppsFlyerEventBus.publish("t$thread-$index")
                    }
                }
            }
            startGate.countDown()
            tasks.forEach { task -> task.get(TASK_TIMEOUT_SECONDS, TimeUnit.SECONDS) }
        } finally {
            executor.shutdownNow()
        }
    }

    private companion object {
        private const val EVENT_A = """{"name":"onDeepLinking","data":{"status":"FOUND"}}"""
        private const val EVENT_B = """{"name":"onConversionDataSuccess","data":{}}"""
        private const val EVENT_C = """{"name":"onSessionReady"}"""

        // Mirrors MAX_PENDING_EVENTS in AppsFlyerEventBus.kt, which is file-private there.
        private const val MAX_PENDING_EVENTS = 64

        private const val THREAD_COUNT = 8
        private const val EVENTS_PER_THREAD = 50
        private const val TASK_TIMEOUT_SECONDS = 10L
    }
}
