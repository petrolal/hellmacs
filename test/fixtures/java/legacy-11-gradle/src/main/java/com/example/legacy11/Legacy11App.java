package com.example.legacy11;

public class Legacy11App {
    public static String greet(String name) {
        // Java 11 String.isBlank() and var
        var trimmed = name.strip();
        return "Hello from Java 11, " + trimmed + "!";
    }

    public static void main(String[] args) {
        System.out.println(greet("Hellmacs"));
    }
}
