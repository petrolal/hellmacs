package dev.hellmacs.demo;

/** Entry point. Set a breakpoint on the greeting line to test the debugger. */
public class App {
    public static void main(String[] args) {
        Greeter greeter = new Greeter("Hellmacs");
        Person person = new Person("Doomguy", 42);
        String greeting = greeter.greet(person.getName());
        System.out.println(greeting);
    }
}
