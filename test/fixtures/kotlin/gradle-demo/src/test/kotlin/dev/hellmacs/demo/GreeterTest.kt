package dev.hellmacs.demo

import kotlin.test.Test
import kotlin.test.assertEquals

class GreeterTest {
    @Test
    fun greetsByName() {
        assertEquals("Hello, Ann, from Hellmacs!", Greeter("Hellmacs").greet("Ann"))
    }

    @Test
    fun `greets someone with a backticked name`() {
        assertEquals("Hello, Bob, from Hellmacs!", Greeter("Hellmacs").greet("Bob"))
    }
}
