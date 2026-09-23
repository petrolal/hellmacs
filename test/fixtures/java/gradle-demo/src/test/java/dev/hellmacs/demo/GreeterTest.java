package dev.hellmacs.demo;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class GreeterTest {
    @Test
    void greetsByName() {
        assertEquals("Hello, Ann, from Hellmacs!", new Greeter("Hellmacs").greet("Ann"));
    }

    @Test
    void lombokGettersWork() {
        assertEquals(42, new Person("Doomguy", 42).getAge());
    }
}
