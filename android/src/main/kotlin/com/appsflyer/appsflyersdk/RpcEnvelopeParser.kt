package com.appsflyer.appsflyersdk

import io.flutter.plugin.common.MethodCall
import org.json.JSONObject

/**
 * Parses the internal `executeRpc` transport envelope `{method, params}`.
 *
 * Malformed envelopes are integration errors inside the plugin bridge, not
 * user-facing RPC failures. Parsing is intentionally outside dispatch
 * `try/catch` so violations fail fast with [IllegalStateException] instead of
 * being converted to `UNEXPECTED_ERROR`.
 */
internal object RpcEnvelopeParser {
    private const val VIOLATION_PREFIX = "RPC envelope contract violation: "

    fun parse(call: MethodCall): Pair<String, JSONObject> = parse(call.arguments)

    fun parse(arguments: Any?): Pair<String, JSONObject> {
        val envelope = arguments as? Map<String, Any?>
            ?: envelopeViolation("arguments must be Map")
        val method = envelope["method"] as? String
            ?: envelopeViolation("method must be String")
        val paramsMap = envelope["params"] as? Map<*, *>
            ?: envelopeViolation("params must be Map")
        return method to JSONObject(paramsMap)
    }

    private fun envelopeViolation(detail: String): Nothing {
        throw IllegalStateException(VIOLATION_PREFIX + detail)
    }
}
