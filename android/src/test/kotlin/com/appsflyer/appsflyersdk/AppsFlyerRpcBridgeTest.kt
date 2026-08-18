package com.appsflyer.appsflyersdk

import com.appsflyer.pluginbridge.model.RpcResponse

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** Stands in for the runner wrapping `AppsFlyerRpcHandler`, which needs a real Android context. */
private class FakeRpcRequestRunner : RpcRequestRunner {
    override fun execute(requestJson: String): RpcResponse = RpcResponse.VoidSuccess
}

class AppsFlyerRpcBridgeTest {

    private val created = AtomicInteger()

    @Before
    fun setUp() = AppsFlyerRpcBridge.reset()

    @After
    fun tearDown() = AppsFlyerRpcBridge.reset()

    private fun createRunner(): RpcRequestRunner {
        created.incrementAndGet()
        return FakeRpcRequestRunner()
    }

    @Test
    fun shared_withoutARunner_createsOne() {
        val runner = AppsFlyerRpcBridge.shared(::createRunner)

        assertEquals(1, created.get())
        assertEquals(RpcResponse.VoidSuccess, runner.execute(REQUEST))
    }

    @Test
    fun shared_repeatedCalls_reuseTheSameRunner() {
        val first = AppsFlyerRpcBridge.shared(::createRunner)
        val second = AppsFlyerRpcBridge.shared(::createRunner)

        assertSame(first, second)
        assertEquals(1, created.get())
    }

    @Test
    fun shared_afterEngineRecreation_reusesTheRunnerOfThePreviousEngine() {
        // The plugin instance goes away with its engine; the runner belongs to the process, so
        // the engine built after a back press reattaches to the already configured bridge.
        val firstEngine = AppsFlyerRpcBridge.shared(::createRunner)

        val secondEngine = AppsFlyerRpcBridge.shared(::createRunner)

        assertSame(firstEngine, secondEngine)
        assertEquals(1, created.get())
    }

    @Test
    fun shared_fromConcurrentEngines_createsExactlyOneRunner() {
        val start = CountDownLatch(1)
        val done = CountDownLatch(ENGINES)
        val resolved = Collections.synchronizedList(mutableListOf<RpcRequestRunner>())
        val pool = Executors.newFixedThreadPool(ENGINES)

        repeat(ENGINES) {
            pool.execute {
                start.await()
                resolved += AppsFlyerRpcBridge.shared(::createRunner)
                done.countDown()
            }
        }
        start.countDown()
        assertTrue(done.await(5, TimeUnit.SECONDS))
        pool.shutdownNow()

        assertEquals(1, created.get())
        assertEquals(1, resolved.distinct().size)
    }

    @Test
    fun reset_dropsTheRunnerSoTheNextCallBuildsANewOne() {
        val first = AppsFlyerRpcBridge.shared(::createRunner)

        AppsFlyerRpcBridge.reset()
        val second = AppsFlyerRpcBridge.shared(::createRunner)

        assertNotSame(first, second)
        assertEquals(2, created.get())
    }

    private companion object {
        const val REQUEST = """{"method":"getSdkVersion","params":{}}"""
        const val ENGINES = 8
    }
}
