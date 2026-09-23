# Java fixtures

Two small projects with identical sources, one built with Gradle and one with Maven,
used to verify Hellmacs' Java support (roadmap Phase 6):

- `App` — a `main` to set breakpoints in.
- `Greeter` — a plain class for completion, navigation and refactoring.
- `Person` — Lombok `@Data`: its getters exist only after annotation processing.
- `GreeterTest` — passes.
- `BrokenTest` — fails on purpose, but only with `-Dhellmacs.fail=true`, so a normal
  build passes and failure handling can still be tested.

Both target Java 21 (the minimum JDTLS runs on) and include their build tool's wrapper,
so the Hellmacs build detection (wrapper first) is exercised too:

    cd gradle-demo && ./gradlew test                       # passes
    cd gradle-demo && ./gradlew test -Dhellmacs.fail=true  # BrokenTest fails
    cd maven-demo  && ./mvnw -B test                       # passes
    cd maven-demo  && ./mvnw -B test -Dhellmacs.fail=true  # BrokenTest fails
