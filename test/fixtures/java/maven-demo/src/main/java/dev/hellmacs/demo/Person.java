package dev.hellmacs.demo;

import lombok.AllArgsConstructor;
import lombok.Data;

/** Lombok: getName(), getAge(), equals, ... exist only after annotation processing. */
@Data
@AllArgsConstructor
public class Person {
    private String name;
    private int age;
}
