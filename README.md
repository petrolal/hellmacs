```
  _   _ _____ _     _     __  __    _    ____ ____
 | | | | ____| |   | |   |  \/  |  / \  / ___/ ___|
 | |_| |  _| | |   | |   | |\/| | / _ \| |   \___ \
 |  _  | |___| |___| |___| |  | |/ ___ \ |___ ___) |
 |_| |_|_____|_____|_____|_|  |_/_/   \_\____|____/
       [ THE INFERNAL JVM HACKING ENVIRONMENT ]
```

**HELLMACS: FORGED IN BYTECODE. TEMPERED IN HELLFIRE.**

Rip and tear through monolithic runtimes. Hellmacs is an unholy, brutally optimized Emacs distribution engineered to subjugate the Java Virtual Machine. No bloat. No mercy. Just raw, unrelenting execution speed.

> *"Abandon all slow startup times, ye who enter here."*

---

## ⚡ Features & Highlights

* **Flawless LSP Annihilation** — Eclipse JDTLS for Java, `kotlin-language-server` for Kotlin, and `clojure-lsp` for Clojure: semantic completion, navigation, refactoring, code actions, and real-time diagnostics.
* **Hot-Reload Damnation** — Java Hot Code Replacement (HCR) into a running, debugged JVM and Clojure buffer reloads into a live CIDER REPL on `C-c h r`.
* **Full DAP Debugging** — Step-by-step debugger (`dap-mode`), breakpoints, conditional break, log points, interactive REPL, locals, watches, and single-key stepping.
* **Modern Completion Nether-Stack** — Minimalist, responsive UI built on [Vertico](https://github.com/minad/vertico), [Consult](https://github.com/minad/consult), [Marginalia](https://github.com/minad/marginalia), [Orderless](https://github.com/oantolin/orderless), and [Corfu](https://github.com/minad/corfu) + [Cape](https://github.com/minad/cape).
* **Aggressive Garbage Execution** — Custom low-pause GC tuning, deferred incremental loading, and native compilation that cuts Emacs startup latency down to **~0.05 seconds**.
* **Stock Emacs DNA (The 40-Year Purist Guarantee)** — Pure GNU Emacs keybindings (`C-x`, `C-c`, `M-x`, `M-.`, `dired`, buffers) with zero Vim/Evil modal interference. Built so a 60-year-old veteran with 40 years of muscle memory feels immediately at home while wielding 2026 enterprise IDE firepower. Custom commands live cleanly under `C-c`.
* **Enterprise-Grade Reproducibility** — Clean XDG directory isolation, pinned checksummed dependencies, CLI tooling (`bin/hellmacs`), corporate proxy/CA support, offline bundles, and zero telemetry.

---

## 🚀 Quick Start

### 1. Requirements
* Emacs 29.1+ with native compilation
* Git 2.25+
* JDK 21+ (`JAVA_HOME` or `java` on `PATH`)

### 2. Install
```sh
git clone https://github.com/petrolal/hellmacs.git ~/.config/emacs
~/.config/emacs/bin/hellmacs install --env
emacs
```

---

## 📚 Documentation

Detailed guides and references are organized in the [`docs/`](docs/) directory:

| Guide | Description |
|---|---|
| 🏁 **[Getting Started](docs/getting-started.md)** | Installation, prerequisites, directory layout, and initial setup |
| ⚙️ **[Configuration](docs/configuration.md)** | Module system (`hellmacs!`), flags, custom packages, and profiles |
| ☕ **[JVM Development](docs/jvm-development.md)** | Java (JDTLS, Lombok, Maven/Gradle), Kotlin, and Clojure workflows |
| 🐞 **[Debugging & Hot Reload](docs/debugging.md)** | DAP debugging, breakpoints, variable inspection, and Hot Code Replace |
| 🔍 **[Completion & Navigation](docs/completion-and-navigation.md)** | Corfu, Cape, Vertico, Consult, and LSP code intelligence |
| ⌨️ **[Keybindings Reference](docs/keybindings.md)** | Complete keyboard cheatsheet for standard and leader commands |
| 💻 **[CLI Reference](docs/cli.md)** | `bin/hellmacs` commands (`install`, `sync`, `upgrade`, `doctor`, `lock`) |
| 🗺️ **[Enterprise Roadmap](docs/roadmap.md)** | Multi-phase plan and IntelliJ/Eclipse parity checklist (in English) |

---

## 📂 Directory Layout

```
hellmacs/
├── early-init.el            # Pre-frame boot: GC tuning, dir layout, UI chrome suppression
├── init.el                  # Bootstrap orchestrator: core, package manager, modules
├── bin/hellmacs             # Command-line tool: install, sync, upgrade, lock, gc, env, doctor
├── core/                    # Engine internals (module loader, lifecycle hooks, keybind helpers)
├── modules/<group>/<name>/  # Feature modules, enabled via `hellmacs!' in your init.el
├── docs/                    # Complete user and architectural documentation
│   ├── getting-started.md
│   ├── configuration.md
│   ├── jvm-development.md
│   ├── debugging.md
│   ├── completion-and-navigation.md
│   ├── keybindings.md
│   ├── cli.md
│   └── roadmap.md           # Enterprise roadmap & parity targets
├── themes/                  # Standalone themes (hellmacs-inferno-theme.el)
├── test/                    # Unit and integration test suites (`bin/hellmacs test`)
└── static/                  # User config starter templates (init, packages, config)
```

---

## 🛡️ License

Hellmacs is free and open-source software licensed under the **GNU General Public License v3.0 (GPL-3.0-or-later)**.

Copyright (C) 2026 petrolal <petrolalucas@gmail.com>

* **Copyleft / Open Source Requirement:** Anyone who modifies, forks, or distributes Hellmacs (or derivative works) **must** release their changes as open source under the GNU GPL v3.0 license.
* **Attribution / Name Protection:** All copyright notices and author attributions to `petrolal` must be preserved.
* See the full license in [`LICENSE`](LICENSE).
