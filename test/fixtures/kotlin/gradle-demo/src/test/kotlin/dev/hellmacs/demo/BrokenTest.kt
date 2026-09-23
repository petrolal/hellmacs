package dev.hellmacs.demo

import kotlin.test.Test
import kotlin.test.assertEquals
import org.junit.jupiter.api.condition.EnabledIfSystemProperty

/**
 * Fails on purpose, but only when run with -Dhellmacs.fail=true, so a
 * normal build passes and failure handling can still be tested.
 */
class BrokenTest {
    @Test
    @EnabledIfSystemProperty(named = "hellmacs.fail", matches = "true")
    fun failsOnPurpose() {
        assertEquals("heaven", Greeter("Hellmacs").greet("Ann"))
    }
}
