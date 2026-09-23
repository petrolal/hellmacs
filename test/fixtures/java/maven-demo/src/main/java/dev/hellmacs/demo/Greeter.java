package dev.hellmacs.demo;

/** A plain class: completion, navigation and refactoring targets. */
public class Greeter {
    private final String from;

    public Greeter(String from) {
        this.from = from;
    }

    public String greet(String name) {
        return "Hello, " + name + ", from " + from + "!";
    }
}
