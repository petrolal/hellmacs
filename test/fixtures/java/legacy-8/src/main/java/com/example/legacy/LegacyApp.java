package com.example.legacy;

public class LegacyApp {
    public static String greet(String name) {
        return "Hello from Java 8, " + name + "!";
    }

    public static void main(String[] args) {
        System.out.println(greet("Hellmacs"));
    }
}
