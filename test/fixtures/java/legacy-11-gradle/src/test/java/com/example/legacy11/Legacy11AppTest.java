package com.example.legacy11;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class Legacy11AppTest {
    @Test
    public void testGreet() {
        assertEquals("Hello from Java 11, World!", Legacy11App.greet(" World  "));
    }
}
