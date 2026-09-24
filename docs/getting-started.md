# Getting Started with Hellmacs

Welcome to **Hellmacs** — the infernal, enterprise-grade JVM hacking environment for Emacs.

---

## Prerequisites

Before installing Hellmacs, ensure you have the following installed on your system:

| Tool | Minimum Version | Purpose |
|---|---|---|
| **Emacs** | `29.1+` (30.1+ recommended for `clojure-ts-mode`) | Core editor with native compilation support |
| **Git** | `2.25+` | Package fetching via Elpaca & Magit |
| **JDK** | `21+` | Needed to run Eclipse JDTLS (target projects can use Java 8/11/17/21+) |
| **C Compiler & Make** | `gcc` / `clang`, `make` | Building Tree-sitter grammars (pinned during sync) |
| **ripgrep & fd** | Latest | Fast project search in Vertico/Consult (`rg`, `fd`) |

Optional tools:
* `mvn` / `gradle`: Maven / Gradle for building projects without wrapper scripts.
* `unzip`: Required to install pinned Kotlin / Clojure language servers.
* `lein` / `clojure` / `bb`: Clojure REPL tooling for CIDER.

---

## Installation

### 1. Clone the repository
Clone Hellmacs to your Emacs configuration directory:

```sh
# Standard installation
git clone https://github.com/petrolal/hellmacs.git ~/.config/emacs

# Or clone to any directory and point Emacs to it:
git clone https://github.com/petrolal/hellmacs.git ~/hellmacs
```

### 2. Run the installer
Run `bin/hellmacs install` with `--env` to create your user configuration and save your shell environment (`JAVA_HOME`, `PATH`, etc.):

```sh
~/.config/emacs/bin/hellmacs install --env
```

What `install` does:
1. Creates your isolated user configuration in `~/.config/hellmacs/` from templates in `static/`.
2. Runs `bin/hellmacs sync` to download and compile all packages declared in enabled modules.
3. Saves environment variables (`JAVA_HOME`, `PATH`, etc.) into `~/.local/share/hellmacs/env.eld`.
4. Runs `bin/hellmacs doctor` to verify your environment.

### 3. Start Hellmacs
Launch Emacs:

```sh
emacs
# or if cloned to a custom directory:
emacs --init-directory ~/hellmacs
```

---

## Directory Layout & State Isolation

Hellmacs strictly follows the **XDG Base Directory Specification**, keeping your `$HOME` clean:

| Purpose | Directory Path | Safe to delete? |
|---|---|---|
| **User Configuration** | `~/.config/hellmacs/` (or `$HELLMACSDIR`) | **No** — this contains your personal `init.el`, `config.el`, and `packages.el` |
| **Installed Packages & Profiles** | `~/.local/share/hellmacs/` | **Yes** — regenerated with `bin/hellmacs sync` |
| **Caches & Native Compilations** | `~/.cache/hellmacs/` | **Yes** — automatically rebuilt as needed |
| **State, History & Undo Sessions** | `~/.local/state/hellmacs/` | **Yes** — but your undo history, recent files, and bookmarks will be reset |

---

## Next Steps

* [Configuration Guide](configuration.md) — Learn how to enable/disable modules and flags.
* [JVM Development](jvm-development.md) — Set up Java, Kotlin, and Clojure workflows.
* [Debugging Guide](debugging.md) — Use DAP mode, breakpoints, and hot code replacement.
* [Keybindings Reference](keybindings.md) — Explore the full keyboard shortcut map.
