package dev.hellmacs.demo

/** Entry point. Set a breakpoint on the greeting line to test the debugger. */
fun main(args: Array<String>) {
    val greeter = Greeter("Hellmacs")
    val person = Person("Doomguy", 42)
    val greeting = greeter.greet(person.name)
    println(greeting)
}
