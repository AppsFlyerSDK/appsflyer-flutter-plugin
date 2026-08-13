package com.appsflyer.appsflyersdk

import org.junit.Assert.assertEquals
import org.junit.Test

class RpcEnvelopeParserTest {

    @Test
    fun parse_validEnvelope_returnsMethod() {
        val (method, _) = RpcEnvelopeParser.parse(
            mapOf(
                "method" to "start",
                "params" to mapOf("awaitResponse" to true),
            ),
        )

        assertEquals("start", method)
    }

    @Test
    fun parse_emptyParamsMap_succeeds() {
        val (method, _) = RpcEnvelopeParser.parse(
            mapOf(
                "method" to "disableAppSetId",
                "params" to emptyMap<String, Any?>(),
            ),
        )

        assertEquals("disableAppSetId", method)
    }

    @Test(expected = IllegalStateException::class)
    fun parse_nonMapArguments_throwsContractViolation() {
        RpcEnvelopeParser.parse("not-a-map")
    }

    @Test
    fun parse_nonMapArguments_includesContractPrefix() {
        try {
            RpcEnvelopeParser.parse(null)
        } catch (error: IllegalStateException) {
            assertEquals(
                "RPC envelope contract violation: arguments must be Map",
                error.message,
            )
            return
        }
        throw AssertionError("Expected IllegalStateException")
    }

    @Test(expected = IllegalStateException::class)
    fun parse_missingMethod_throwsContractViolation() {
        RpcEnvelopeParser.parse(mapOf("params" to emptyMap<String, Any?>()))
    }

    @Test(expected = IllegalStateException::class)
    fun parse_nonStringMethod_throwsContractViolation() {
        RpcEnvelopeParser.parse(
            mapOf(
                "method" to 123,
                "params" to emptyMap<String, Any?>(),
            ),
        )
    }

    @Test(expected = IllegalStateException::class)
    fun parse_missingParams_throwsContractViolation() {
        RpcEnvelopeParser.parse(mapOf("method" to "start"))
    }

    @Test(expected = IllegalStateException::class)
    fun parse_nonMapParams_throwsContractViolation() {
        RpcEnvelopeParser.parse(
            mapOf(
                "method" to "start",
                "params" to "not-a-map",
            ),
        )
    }
}
