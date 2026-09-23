package dev.hellmacs.demo

/** A plain class: completion, navigation and refactoring targets. */
class Greeter(private val from: String) {
    fun greet(name: String): String {
        return "Hello, $name, from $from!"
    }
}
