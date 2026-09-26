package com.example.legacy;

import org.junit.Test;
import static org.junit.Assert.assertEquals;

public class LegacyAppTest {
    @Test
    public void testGreet() {
        assertEquals("Hello from Java 8, World!", LegacyApp.greet("World"));
    }
}
