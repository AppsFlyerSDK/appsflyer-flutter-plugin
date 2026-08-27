package com.appsflyer.appsflyersdk

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper

import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class AppsFlyerContextHolderTest {

    private val appContext: Context = ContextWrapper(null)

    /** Stands in for a plugin instance; the holder uses owners as identity keys only. */
    private val engineA = Any()
    private val engineB = Any()

    @Before
    fun setUp() = AppsFlyerContextHolder.reset()

    @After
    fun tearDown() = AppsFlyerContextHolder.reset()

    @Test
    fun current_withoutAnActivity_returnsTheApplicationContext() {
        AppsFlyerContextHolder.setAppContext(appContext)

        assertSame(appContext, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_withAnAttachedActivity_prefersIt() {
        val activity = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, activity)

        assertSame(activity, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_afterDetach_fallsBackToTheApplicationContext() {
        val activity = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, activity)

        AppsFlyerContextHolder.detachActivity(engineA)

        assertSame(appContext, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_whenAnotherEngineSharesTheActivity_survivesTheFirstDetach() {
        val shared = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, shared)
        AppsFlyerContextHolder.attachActivity(engineB, shared)

        AppsFlyerContextHolder.detachActivity(engineA)

        assertSame(shared, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_whenTheLastEngineSharingTheActivityDetaches_fallsBack() {
        val shared = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, shared)
        AppsFlyerContextHolder.attachActivity(engineB, shared)

        AppsFlyerContextHolder.detachActivity(engineA)
        AppsFlyerContextHolder.detachActivity(engineB)

        assertSame(appContext, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_withTwoEnginesOnDifferentActivities_prefersTheMostRecent() {
        val first = Activity()
        val second = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, first)
        AppsFlyerContextHolder.attachActivity(engineB, second)

        assertSame(second, AppsFlyerContextHolder.current())
    }

    @Test
    fun current_afterTheMostRecentEngineDetaches_fallsBackToTheOtherActivity() {
        val first = Activity()
        val second = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, first)
        AppsFlyerContextHolder.attachActivity(engineB, second)

        AppsFlyerContextHolder.detachActivity(engineB)

        assertSame(first, AppsFlyerContextHolder.current())
    }

    @Test
    fun attachActivity_onReattach_becomesTheMostRecentAgain() {
        val activityA = Activity()
        val activityB = Activity()
        val rotatedA = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, activityA)
        AppsFlyerContextHolder.attachActivity(engineB, activityB)

        // Configuration change on engine A: detach then reattach with a recreated Activity.
        AppsFlyerContextHolder.detachActivity(engineA)
        AppsFlyerContextHolder.attachActivity(engineA, rotatedA)

        assertSame(rotatedA, AppsFlyerContextHolder.current())
    }

    @Test
    fun attachActivity_twiceWithoutDetach_replacesTheOwnersActivity() {
        val stale = Activity()
        val fresh = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, stale)
        AppsFlyerContextHolder.attachActivity(engineA, fresh)

        AppsFlyerContextHolder.detachActivity(engineA)

        assertSame(appContext, AppsFlyerContextHolder.current())
    }

    @Test
    fun detachActivity_forAnEngineThatNeverAttached_isANoOp() {
        val activity = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, activity)

        AppsFlyerContextHolder.detachActivity(engineB)

        assertSame(activity, AppsFlyerContextHolder.current())
    }

    @Test
    fun detachActivity_calledTwiceForTheSameEngine_isANoOp() {
        val activity = Activity()
        AppsFlyerContextHolder.setAppContext(appContext)
        AppsFlyerContextHolder.attachActivity(engineA, activity)

        // onDetachedFromActivity followed by onDetachedFromEngine.
        AppsFlyerContextHolder.detachActivity(engineA)
        AppsFlyerContextHolder.detachActivity(engineA)

        assertSame(appContext, AppsFlyerContextHolder.current())
    }

    @Test(expected = IllegalStateException::class)
    fun current_beforeAttach_fails() {
        AppsFlyerContextHolder.current()
    }

    @Test
    fun hasContext_tracksWhetherAnyContextIsAvailable() {
        assertFalse(AppsFlyerContextHolder.hasContext())

        AppsFlyerContextHolder.setAppContext(appContext)

        assertTrue(AppsFlyerContextHolder.hasContext())
    }

    @Test
    fun hasContext_withOnlyAnActivity_isTrue() {
        AppsFlyerContextHolder.attachActivity(engineA, Activity())

        assertTrue(AppsFlyerContextHolder.hasContext())
    }
}
