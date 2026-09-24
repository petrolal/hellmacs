# JVM Development Guide

Hellmacs is built first and foremost as a high-performance environment for the Java Virtual Machine ecosystem (Java, Kotlin, Clojure, Scala, Groovy).

---

## Java Development (`:lang java`)

Java support is powered by **Eclipse JDTLS**, **LSP Mode**, **Tree-sitter**, and **DAP Mode**.

### Enabling Java
In `~/.config/hellmacs/init.el`:

```elisp
(hellmacs! :tools
           build              ; Gradle / Maven build integration
           debugger           ; DAP debugger & Hot Code Replace
           lsp                ; LSP Mode
           magit              ; Git interface

           :lang
           (java +lombok +tree-sitter)) ; Java module with Lombok agent and Tree-sitter
```

Run `bin/hellmacs sync` to download JDTLS, Lombok, the Java debug server, and compile tree-sitter grammars.

### First Launch & Project Import
When you open a `.java` file in a Maven or Gradle project:
1. `lsp-mode` asks to import the project root directory. Choose **Import** (saved automatically).
2. The echo area displays `[FORGE IGNITED]` while JDTLS starts up.
3. Once indexed, `[DAEMON READY]` appears, and the mode-line reports `JVM:ready`.

### Java Keybindings (`C-c l j`)
| Key | Command | Description |
|---|---|---|
| `C-c l j b` | `lsp-java-build-project` | Trigger a full/incremental JDTLS build |
| `C-c l j u` | `lsp-java-update-project-configuration` | Re-import `pom.xml` or `build.gradle` changes |
| `C-c l j o` | `lsp-java-organize-imports` | Clean and optimize Java imports |
| `C-c l j g` | `lsp-java-generate-getters-and-setters` | Generate getters/setters for fields |
| `C-c l j s` | `lsp-java-generate-to-string` | Generate `toString()` method |
| `C-c l j e` | `lsp-java-generate-equals-and-hash-code` | Generate `equals()` and `hashCode()` |
| `C-c l j i` | `lsp-java-add-unimplemented-methods` | Implement interface or abstract methods |
| `C-c l j m` | `lsp-java-extract-method` | Refactor: Extract selected code to a method |
| `C-c l j v` | `lsp-java-extract-to-local-variable` | Refactor: Extract expression to local variable |
| `C-c l j c` | `lsp-java-extract-to-constant` | Refactor: Extract expression to constant |
| `C-c l j h` | `lsp-java-type-hierarchy` | View class/type hierarchy |
| `C-c l j t` | `hellmacs-build-test-at-point` | Run the test method at point |
| `C-c l j T` | `hellmacs-build-test-class` | Run the entire test class |

### Building with Maven & Gradle (`:tools build`)
* `C-x p c` (`project-compile`): Runs Gradle or Maven build tasks using the wrapper (`./gradlew` / `./mvnw`) or system binaries.
* `M-g n` / `M-g p`: Jump to next / previous compilation error or failing test assertion in buffer.

---

## Kotlin Development (`:lang kotlin`)

Kotlin support is powered by `kotlin-language-server` and `kotlin-ts-mode`.

### Enabling Kotlin
```elisp
(hellmacs! :tools
           build
           lsp
           :lang
           (kotlin +tree-sitter))
```

### Kotlin Workflow
* **Server**: Automatically downloaded and pinned by `bin/hellmacs sync`.
* **Navigation & Refactoring**: Full `M-.` (Go to Definition), `M-?` (References), semantic rename (`C-c l r r`), and parameter hints.
* **Testing & Building**:
  * `C-c l k b`: Build Kotlin project via Gradle.
  * `C-c l k t`: Run the test method at point (supports backticked names).
  * `C-c l k T`: Run the test class.

---

## Clojure Development (`:lang clojure`)

Clojure support combines **CIDER** for interactive REPL-driven development with **clojure-lsp** for semantic code intelligence.

### Enabling Clojure
```elisp
(hellmacs! :tools
           lsp
           :lang
           (clojure +tree-sitter))
```

### Clojure Keybindings
* `C-c M-j`: Jack in (starts REPL via `lein`, `clojure`, or `bb`).
* `C-c M-c`: Connect to an existing remote/local nREPL server.
* `C-c C-k`: Load and compile current Clojure buffer.
* `C-M-x`: Evaluate top-level form at point.
* `C-c C-t t`: Run the test under point.
* `C-c C-z`: Switch between Clojure buffer and REPL buffer.
* `C-c h r`: Reload current buffer changes directly into the active REPL.

---

## Troubleshooting Project Imports

If you see `[BYTECODE PURGATORY] <project> failed to import: ...` and `JVM:purgatory` on the mode-line:
1. **Toolchain Version Mismatch**: Your build may specify a JDK version not currently on your system. Install the required JDK (via SDKMAN or system package manager).
2. **Re-import Project**: Run `C-c l j u` (`lsp-java-update-project-configuration`) to force JDTLS to re-evaluate the build configuration.
3. **Environment Sync**: Run `bin/hellmacs env` in your terminal to refresh `PATH` and `JAVA_HOME` variables recognized by Emacs.
