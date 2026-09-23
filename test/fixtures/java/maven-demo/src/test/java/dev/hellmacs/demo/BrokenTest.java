package dev.hellmacs.demo;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * Fails on purpose, but only when run with -Dhellmacs.fail=true, so a
 * normal build passes and failure handling can still be tested.
 */
class BrokenTest {
    @Test
    @EnabledIfSystemProperty(named = "hellmacs.fail", matches = "true")
    void failsOnPurpose() {
        assertEquals("heaven", new Greeter("Hellmacs").greet("Ann"));
    }
}
