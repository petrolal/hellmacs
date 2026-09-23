// Hellmacs test fixture: a small Gradle Kotlin project with JUnit tests.
plugins {
    kotlin("jvm") version "2.1.10"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

application {
    mainClass.set("dev.hellmacs.demo.AppKt")
}

tasks.test {
    useJUnitPlatform()
    // BrokenTest only runs (and fails) with -Dhellmacs.fail=true.
    systemProperty("hellmacs.fail", System.getProperty("hellmacs.fail", "false"))
}
