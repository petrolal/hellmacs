# JVM Integration Contracts & Tooling Specifications

## 1. Language Server Protocol (LSP) Subsystem

```yaml
lsp_architecture:
  client_package: "lsp-mode (default) or eglot (+eglot flag)"
  keymap_prefix: "C-c l"
  java:
    server: "Eclipse JDTLS"
    wrapper: "lsp-java"
    javaagent: "Lombok (pinned SHA-256 download via +lombok)"
    memory_limit: "2GB heap (lsp-java-vmargs)"
    project_detection: ["pom.xml", "build.gradle", "build.gradle.kts", ".project"]
  kotlin:
    server: "fwcd/kotlin-language-server (pinned release binary)"
    wrapper: "lsp-mode kotlin integration"
    memory_limit: "2GB heap"
    project_detection: ["build.gradle.kts", "build.gradle", "pom.xml"]
  clojure:
    server: "clojure-lsp (pinned platform-specific binary)"
    repl: "CIDER (jack-in via lein/clj/bb)"
    project_detection: ["deps.edn", "project.clj", "bb.edn"]
```

---

## 2. Debug Adapter Protocol (DAP) Subsystem

```yaml
debugger_architecture:
  package: "dap-mode"
  keymap_prefix: "C-c d"
  java_adapter: "Microsoft java-debug (pinned JARs, extracted during sync)"
  capabilities:
    - line_breakpoints: "dap-breakpoint-toggle (C-c d b)"
    - conditional_breakpoints: "dap-breakpoint-condition (C-c d B)"
    - log_points: "dap-breakpoint-log-message (C-c d L)"
    - hot_code_replacement: "hellmacs-crucible (C-c h r)"
    - repetitive_stepping: "Single key 'n', 'i', 'o', 'c' loop"
```

---

## 3. Build Tooling & Compilation Regex Engine

* **Trigger**: `C-x p c` (`project-compile`) detects root `./gradlew` or `./mvnw`.
* **Output Parsing**: Emacs `compilation-mode` augmented with custom regex matchers in [`modules/tools/build/autoload.el`](file:///home/petrolal/hellmacs/modules/tools/build/autoload.el):
  * Java stack traces: `at com.example.Foo.method(Foo.java:42)`
  * Kotlin compilation errors: `e: /path/to/File.kt:12:5: Error message`
  * Maven compiler errors: `[ERROR] /path/to/File.java:[23,10] Error message`
  * Failing test assertion jump links: `M-g n` (next error/failure), `M-g p` (previous).
