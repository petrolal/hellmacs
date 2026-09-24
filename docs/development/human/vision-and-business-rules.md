# Vision, Business Rules & Use Cases

This document describes the core philosophy, business rules, and real-world enterprise use cases of **Hellmacs** for human developers, contributors, and engineering leaders.

---

## 1. Product Vision & Target Audience

Hellmacs is an **enterprise-grade Emacs distribution designed specifically for the JVM ecosystem** (Java, Kotlin, Clojure, Scala, Groovy).

### The Problem It Solves
Monolithic modern IDEs (IntelliJ IDEA Ultimate, Eclipse, VS Code with heavy extension packs) suffer from:
* High resource consumption (several gigabytes of idle RAM).
* Slow startup and indexing freezes.
* Frequent modal disruptions and heavy UI bloat.
* Fragmented configurations across team members.

### The Core Thesis: Purist GNU Emacs DNA + Modern Enterprise Horsepower

Most modern Emacs distributions (such as Doom Emacs or Spacemacs) made a fundamental design compromise: they assumed that "modernizing" Emacs required converting it into a **modal Vim/Evil clone** with leader keys bound to the spacebar (`SPC f f`, etc.).

While this appeals to Vim refugees, it creates a fatal friction for two major groups:
1. **The 40-Year Emacs Veteran**: A 60-year-old senior engineer or architect who has used GNU Emacs for 20, 30, or 40 years has lifelong, subconscious muscle memory built on `C-x`, `C-c`, `M-x`, `C-s`, `M-f`, `C-y`, buffers, `dired`, `compile`, and Info manuals. Being forced into Vim modal editing or foreign leader schemes destroys their productivity.
2. **The Enterprise JVM Reality**: Vanilla GNU Emacs out-of-the-box requires weeks of manual, fragile Elisp configuration to properly support Eclipse JDTLS, Lombok, DAP debugging, Hot Code Replacement, multi-module Maven/Gradle builds, and strict GC tuning.

**Hellmacs fills this exact void.** It provides the **"Sweet Spot"**:
* **100% Respect for Classic Emacs Reflexes**: Standard GNU keybindings are sacred. No modal editing by default. Custom features live exclusively under `C-c`.
* **Zero-Compromise Enterprise Power**: Full parity with IntelliJ IDEA Ultimate and Eclipse on daily JVM development (Spring Boot, Java 21+, Kotlin, Clojure, Maven, Gradle, DAP debugging, Hot Code Replacement).
* **Instantaneous Performance**: Starts in **~0.05 seconds** with low-pause GC, giving the snappy, responsive feel of a classic editor from the 1980s with the semantic intelligence of a modern 2026 IDE.

### The Target Persona: The Veteran Enterprise Engineer
A senior software engineer, staff architect, or tech lead working at a bank, insurance firm, fintech, or large enterprise software organization who:
* Spends their workday navigating large Spring Boot, Maven, and Gradle codebases.
* Wants to use their beloved, decades-old Emacs reflexes without spending their weekends fixing broken package setups.
* Needs seamless out-of-the-box integration with corporate proxies, internal Maven mirrors (Artifactory/Nexus), multiple JDKs, and step-by-step debugging with live bytecode hot-swapping.

---

## 2. Inviolable Business Rules & Architectural Principles

When building features or extending Hellmacs, these core rules must always be upheld:

```
+-------------------------------------------------------------------------+
|                         HELLMACS BUSINESS RULES                         |
+------------------------------------+------------------------------------+
| 1. Stock Emacs Reflexes            | 5. Offline & Corporate Network     |
|    - Default keys unchanged        |    - Works behind proxy & CA       |
|    - No Vim emulation by default   |    - Offline bundle support        |
+------------------------------------+------------------------------------+
| 2. JVM-First Priority              | 6. Clean XDG Directory Isolation   |
|    - Java is the reference target  |    - Nothing outside XDG dirs      |
|    - Kotlin/Clojure follow pattern |    - Zero home-directory clutter   |
+------------------------------------+------------------------------------+
| 3. Built-ins First                 | 7. Zero Telemetry & Full Privacy   |
|    - project.el, treesit, compile  |    - No data phoned home, ever     |
|    - 3rd-party only where needed   |    - 100% reproducible SBOMs       |
+------------------------------------+------------------------------------+
| 4. Sub-0.12s Startup Budget        | 8. Honest Parity Metrics           |
|    - Compiled static profiles      |    - Clear documentation on what   |
|    - Low-pause GC lifecycle tuning |      matches or differs from IDEs  |
+------------------------------------+------------------------------------+
```

---

## 3. Real-World Enterprise Use Cases

### Use Case 1: The Corporate Monorepo / Multi-Module Build
* **Scenario**: A banking application with 40+ Gradle/Maven sub-modules, internal BOMs, and customized `settings.xml` / `init.gradle` scripts.
* **Hellmacs Solution**: Eclipse JDTLS is automatically mapped to the root project. Hellmacs orchestrates builds via `C-x p c`, capturing compiler errors and test failures with clickable navigation links (`M-g n` / `M-g p`).

### Use Case 2: Multi-JDK Environments (Legacy Java 8/11 + Modern Java 21+)
* **Scenario**: A developer maintains legacy microservices on Java 8/11 while developing new services on Java 21.
* **Hellmacs Solution**: JDTLS runs on Java 21 while dynamically targeting project-specific JVM runtimes and toolchains without conflicting global configurations.

### Use Case 3: Restricted Corporate Network (Proxy + Internal CA + Artifactory)
* **Scenario**: Company laptops block direct public internet access, routing all traffic through corporate HTTP/HTTPS proxies, custom root CAs, and internal artifact mirrors (Nexus/Artifactory).
* **Hellmacs Solution**: `bin/hellmacs install --env` captures proxy settings, CA bundles, and mirrors. Package locks (`bin/hellmacs lock`) and offline bundles ensure zero failures during setup.

### Use Case 4: Fast Feedback Loop with Hot Code Replacement
* **Scenario**: Debugging a complex Spring Boot service where restarting the application takes 45 seconds.
* **Hellmacs Solution**: Attach debugger (`C-c d d`), edit code, and press `C-c h r` (Crucible). JDTLS compiles changed classes and immediately replaces the bytecode in the live JVM without restarting.
