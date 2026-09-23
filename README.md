```
  _   _ _____ _     _     __  __    _    ____ ____
 | | | | ____| |   | |   |  \/  |  / \  / ___/ ___|
 | |_| |  _| | |   | |   | |\/| | / _ \| |   \___ \
 |  _  | |___| |___| |___| |  | |/ ___ \ |___ ___) |
 |_| |_|_____|_____|_____|_|  |_/_/   \_\____|____/
       [ THE INFERNAL JVM HACKING ENVIRONMENT ]
```

**HELLMACS: FORGED IN BYTECODE. TEMPERED IN HELLFIRE.**

Rip and tear through monolithic runtimes. Hellmacs is an unholy, brutally optimized
Emacs distribution engineered to subjugate the Java Virtual Machine. No bloat. No mercy.
Just raw, unrelenting execution speed.

"Abandon all slow startup times, ye who enter here."

## What It Is

Hellmacs fuses the battle-hardened reflexes of stock Emacs keybindings with the
industrial-grade machinery of the JVM. Whether you're slinging Clojure s-expressions,
tearing through raw Java bytecode, or orchestrating massive enterprise daemons, Hellmacs
turns your editor into a high-octane siege engine.

- **Flawless LSP Annihilation** — Eclipse JDTLS for Java, kotlin-language-server for Kotlin and
  clojure-lsp for Clojure are lit (`:tools lsp` + `:lang java` / `kotlin` / `clojure`):
  completion, navigation, refactoring, diagnostics.
- **Hot-reload Damnation** — Java hot code replace into a running, debugged JVM, and Clojure
  reloads into a live CIDER REPL, both on `C-c h r`.
- **Aggressive Garbage Execution** — custom-tuned, low-pause GC hooks and
  native-compilation flags that choke Emacs's own startup latency before it draws breath.
  This part's already lit; see [`early-init.el`](early-init.el) and
  [`core/hellmacs-core.el`](core/hellmacs-core.el).
- **The Nether-Stack** — built on a razor-sharp modern foundation (`elpaca` + `vertico`
  + `corfu`), wrapped in Hellmacs' own obsidian-black, brimstone-red theme.

Lock in. Jack into the daemon. Let the bytecode burn.

## Current stack

The JVM warfare above — JDTLS, Clojure LSP, Kotlin, CIDER-driven REPLs — is the target.
What's actually forged and working right now is the foundation it's built on:

- **JVM languages (opt-in modules, see [Java setup](#java-setup),
  [Kotlin and Clojure](#kotlin-and-clojure)):** `lsp-mode` + `lsp-java` (JDTLS), kotlin-language-server,
  clojure-lsp + CIDER, `dap-mode` + `dap-java` (java-debug), Gradle and Maven through Emacs' own
  `compile`, Lombok support, tree-sitter grammars built and pinned by `sync`, and Magit
- **Package manager:** [Elpaca](https://github.com/progfolio/elpaca) (async, git-based, reproducible)
- **Completion:** `vertico` + `consult` + `marginalia` + `orderless` + `corfu`
- **Keybindings:** stock Emacs keys, no Vim emulation. Hellmacs' own commands live under
  `C-c` (`C-c h` Hellmacs, `C-c f` file, `C-c b` buffer, `C-c s` search, `C-c w` window),
  with `which-key` showing what follows any prefix
- **Undo:** built-in `undo` / `undo-redo`, plus `undo-fu-session` to keep undo history across restarts
- **Theme:** `hellmacs` (in `themes/`, no dependencies): Obsidian Void `#0a0a0c`, Brimstone Red
  `#ff1a40`, Argent Amber `#ff8800`, Toxic Green `#00ff66`, Ash White `#d6d6d8`
- **Startup screen:** the Altar (`*hellmacs*`), with the horned cyber-cat sigil and the startup time

## Directory layout

```
hellmacs/
├── early-init.el            # Pre-frame boot: GC tuning, dir layout, UI chrome suppression
├── init.el                  # Bootstrap orchestrator: core, package manager, modules, user config
├── bin/hellmacs             # Command-line tool: install, sync, upgrade, lock, gc, env, doctor
├── core/                    # Engine internals -- no editing-style opinions
│   ├── hellmacs-lib.el          # Macros (after!, add-hook!, setq-hook!, defadvice!, cmd!), session context
│   ├── hellmacs-core.el         # Startup lifecycle + first-input/file/buffer hooks, GC, XDG dir isolation, defaults
│   ├── hellmacs-packages.el     # use-package settings; loads Elpaca on demand
│   ├── hellmacs-elpaca.el       # Elpaca bootstrap (only for sync / unsynced startup)
│   ├── hellmacs-keybinds.el     # The C-c leader: `hellmacs-leader-def'
│   ├── hellmacs-modules.el      # Module system: `hellmacs!', `modulep!', `package!', profile loading
│   ├── hellmacs-splash.el       # The Altar: startup screen (`C-c h s')
│   ├── hellmacs-ux.el           # Themed quit prompt, [CRITICAL FATALITY] errors, JVM exception colors
│   ├── hellmacs-treesit.el      # Tree-sitter grammars, pinned by commit and built by sync
│   ├── hellmacs-lsp-status.el   # [FORGE IGNITED] / [DAEMON READY] messages for Kotlin and Clojure servers
│   ├── hellmacs-sync.el         # `hellmacs-sync': install packages, write the profile
│   ├── hellmacs-cli.el          # The bin/hellmacs commands
│   └── packages.el              # Packages every config needs (read before modules)
├── modules/<group>/<name>/  # User-facing features, enabled with `hellmacs!'
│   ├── ui/theme/                # Loads the theme (`hellmacs-theme'), line numbers, current line
│   ├── editor/undo/             # Persistent undo history (undo-fu-session)
│   ├── completion/vertico/      # Minibuffer completion + consult (C-c f, C-c b, C-c s)
│   ├── completion/corfu/        # In-buffer completion popup (+tab: TAB completes)
│   ├── tools/lsp/               # Language server client: lsp-mode (+eglot: eglot instead), C-c l
│   ├── tools/build/             # Gradle/Maven through `compile', clickable errors and test failures
│   ├── tools/debugger/          # dap-mode: breakpoints, stepping, tests, hot swap (C-c d)
│   ├── tools/magit/             # Git: Magit (C-x g)
│   ├── lang/java/               # Java through JDTLS (+lombok, +tree-sitter)
│   ├── lang/kotlin/             # Kotlin through kotlin-language-server (+tree-sitter)
│   ├── lang/clojure/            # Clojure: CIDER + clojure-lsp (+tree-sitter)
│   └── config/default/          # Default keys: C-c h (`hellmacs-prefix-map'), C-c q, C-c w; which-key
├── themes/
│   └── hellmacs-theme.el        # The Hellmacs theme (a plain `deftheme')
├── test/                    # ERT suites (`bin/hellmacs test`), Java fixture projects, and
│   └── integration/             # the end-to-end Java check (needs a real install; see Java setup)
├── docs/
│   └── roadmap.md               # Plan for the Doom-style module/sync/CLI architecture
└── static/                  # Starter init.el / packages.el / config.el, and a module template
```

Nothing Hellmacs or its packages write at runtime lands in this checkout:

| What | Where | Safe to delete? |
|---|---|---|
| Your config (`init.el`, `packages.el`, `config.el`, `custom.el`, private `modules/`) | `$HELLMACSDIR`, else `~/.config/hellmacs/`, else `~/.hellmacs.d/` | No -- it's yours |
| Installed packages (Elpaca), synced profile | `$XDG_DATA_HOME/hellmacs/` (`~/.local/share/hellmacs/`) | Yes, then run `bin/hellmacs sync` |
| Native-comp output, package caches | `$XDG_CACHE_HOME/hellmacs/` (`~/.cache/hellmacs/`) | Yes, any time |
| History, recent files, bookmarks, undo, backups | `$XDG_STATE_HOME/hellmacs/` (`~/.local/state/hellmacs/`) | Yes, but that history is gone |

`core/` has no opinions about *how* you edit -- it just makes stock Emacs fast and keeps its
state in the directories above instead of scattering it across `~`. `modules/` is where the actual
editing experience is assembled, one directory per feature, each enabled or disabled from the
`hellmacs!` block in your own `init.el`. `:tools lsp` and `:lang java` (JDTLS) are modules like
any other; `:lang clojure` (Clojure LSP, CIDER) will slot in the same way once it exists.

## Installing

Needs Emacs 29.1+ and git. `bin/hellmacs doctor` checks for these and for the optional tools.

```sh
git clone <this-repo> ~/.config/emacs   # or anywhere, then: emacs --init-directory <dir>
~/.config/emacs/bin/hellmacs install --env
emacs
```

`install` creates your config in `~/.config/hellmacs/` and runs `sync`. `sync` installs every
package the enabled modules declare, which takes about 15 seconds from scratch, then writes a
*profile*. Emacs starts from that profile without loading the package manager at all. `--env`
saves your shell's `PATH`, `JAVA_HOME` and so on, so Emacs finds your tools even when started
from a desktop launcher. Finally `install` runs `doctor`.

## Java setup

Java support is a set of ordinary modules, commented out in the starter `init.el`. Uncomment
them in your `hellmacs!` block, then run `bin/hellmacs sync` (or `install` on a fresh checkout):

```elisp
(hellmacs! ...
           :tools
           build              ; Gradle/Maven through `compile', clickable errors
           debugger           ; dap-mode, C-c d
           lsp                ; lsp-mode, C-c l
           magit              ; Git
           :lang
           (java +lombok)     ; JDTLS; +lombok loads Lombok, +tree-sitter uses java-ts-mode
           ...)
```

`:lang java` needs `:tools lsp`; `:tools debugger` and `:tools build` add debugging and
building. `:tools magit` stands alone.

**Requirements**
- **A JDK 21 or newer** (`JAVA_HOME`, or `java` on the PATH) to run JDTLS. Your projects may
  target older JDKs. `bin/hellmacs install --env` saves `JAVA_HOME` for launchers.
- **Network access on first use**: `sync` downloads JDTLS, the java-debug bundle, the JUnit runner
  (about 110MB in all) and, with `+lombok`, Lombok. Lombok and the java-debug bundle are checked
  against pinned SHA-256 sums. Maven or Gradle fetch a project's own dependencies the first time
  it's imported.
- **Maven** (`mvn`) speeds up the JDTLS install; projects with a `./mvnw` or `./gradlew` wrapper
  need neither tool, others need `mvn` or `gradle`.
- git 2.25 or newer, for Magit.

`bin/hellmacs doctor` checks all of this and says what's missing.

**First use.** Open a `.java` file in a Maven or Gradle project. lsp-mode asks once whether to
import the project root (answer *Import*; it's remembered). The echo area then reads
`[FORGE IGNITED]` and, once indexed, `[DAEMON READY]`, and the mode-line shows
`JVM:igniting` / `JVM:ready` / `JVM:purgatory` (the last build failed).

| Key | Does |
|---|---|
| `M-.` / `M-?` / `M-,` | Definition (library classes are decompiled) / references / back |
| `C-M-.` | Search symbols in the workspace |
| `C-c l a a` / `C-c l r r` / `C-c l r o` | Code action / rename / organize imports |
| `C-c l = =` | Format the buffer |
| `C-c l j` | Java: `b` build in JDTLS, `o` organize imports, `u` re-import pom.xml or build.gradle, `i` add unimplemented methods, `g` getters and setters, `s` toString, `e` equals and hashCode, `m` `v` `c` extract method, variable, constant, `h` type hierarchy, `t` / `T` run the test at point / the class |
| `C-c ! n` `p` `l` | Next / previous / list diagnostics |
| `C-x p c` | Build the project (Gradle or Maven, wrapper first) |
| `M-g n` / `M-g p` | Next / previous compile error or failing test |
| `C-c d` | Debug (see [Keys](#keys)); `C-c h r` hot-swaps the changed classes into the session |
| `C-x g` | Magit status. `C-x M-g` dispatch, `C-c M-g` file blame and log; `?` lists a Magit buffer's keys |

Messages and their themed wording: `[FORGE TEMPERED]` build finished, `[BYTECODE PURGATORY]` build
failed (first error), `[TEST DAMNATION]` tests failed, `[DAEMON BANISHED]` JDTLS exited. They read
plainly with `(setq hellmacs-ux-enable nil)`.

**When a project won't import.** If the echo area says `[BYTECODE PURGATORY] <project> failed to
import: ...` and the mode-line shows `JVM:purgatory` right after opening a file, JDTLS couldn't
read the build (it still starts, but nothing works). The message gives the cause. The usual one is
a Gradle toolchain: the build asks for a JDK (say 21) that isn't installed, so `./gradlew` fails
outside Emacs too. Install that JDK where Gradle finds it (SDKMAN's `sdk install java`, or your
package manager), then `C-c l j u`: the project recovers and `[DAEMON READY]` appears. Other build
failures show their reason the same way, from Gradle's "What went wrong" or Maven's "Failed to
execute goal" line.

Two things to expect: JDTLS reports itself ready a few seconds before workspace-wide search
answers on a larger project, and it uses about 1GB of memory (its heap is capped at 2GB by
`lsp-java-vmargs`).

**Checking an install.** `bin/hellmacs test` runs the unit suites (each language has a
`test/integration/*-e2e.el` too: `java`, `kotlin`, `clojure`). To drive the real thing (JDTLS,
build, debugger, Magit) against the Java fixtures, use `test/integration/java-e2e.el`; its header
says how. `test/integration/java-parity.el` runs an IntelliJ-style feature checklist on any Maven
or Gradle project of yours (on a copy) and prints its timings and JDTLS memory. Run both inside
throwaway directories: they download dependencies and start JDTLS.

## Kotlin and Clojure

Both are ordinary modules, commented out in the starter `init.el`. They need `:tools lsp`; `:tools
build` adds Gradle builds and tests for Kotlin. `bin/hellmacs sync` installs each language server
into the data directory (pinned, SHA-256 checked) and builds the grammars for `+tree-sitter`.

```elisp
(hellmacs! ...
           :tools
           build lsp
           :lang
           kotlin             ; +tree-sitter uses kotlin-ts-mode
           clojure            ; +tree-sitter uses clojure-ts-mode (Emacs 30.1+)
           ...)
```

**Kotlin** (`:lang kotlin`) runs fwcd's kotlin-language-server 1.3.13 on `JAVA_HOME`'s JDK.
- Open a `.kt` file in a Gradle project; lsp-mode asks once to import the root, as for Java.
  `[FORGE IGNITED]`, then `[DAEMON READY]` once the index is built (about 15s on a Spring project);
  `[BYTECODE PURGATORY] ... failed to import: ...` when its Gradle task fails.
- Completion, `M-.` (into Spring and JDK sources too), references, cross-file rename, diagnostics.
- `C-c l k`: `b` build, `t` run the test at point (backticked names work), `T` the class. `C-x p c`
  builds; compile errors (`e: file:///...Foo.kt:12:5`) and failing tests are clickable with `M-g n`.
- **Expect a heavy server**: about 2GB of heap on a real Spring project (`hellmacs-kotlin-vmargs`),
  and few code actions (no extract function or organize imports). It is the only Kotlin server
  Emacs has, and its last release is from January 2025.

**Clojure** (`:lang clojure`) is CIDER for the REPL and clojure-lsp for the code.
- CIDER keeps its own keys: `C-c M-j` jack in (needs the Clojure CLI, `lein` or `bb` on the PATH),
  `C-c M-c` connect, `C-c C-k` load the buffer, `C-M-x` evaluate a top-level form, `C-c C-t t`
  run the test at point, `C-c C-z` the REPL. `C-c h r` reloads a changed buffer into the REPL.
- clojure-lsp gives navigation, rename, references and diagnostics (on save, as clj-kondo does);
  a `clojure-lsp` already on your PATH is used instead of the pinned download.
- Only Linux x86-64 has been run so far; the pins for Linux arm64 and macOS are in the module.

**Tree-sitter** (`+tree-sitter` on `:lang java`, `kotlin` or `clojure`) needs Emacs 29.1+ (Clojure:
30.1+), git and a C compiler. Grammars are built by `sync` into the data directory, each from one
pinned commit; a library from an older pin is rebuilt. Without a grammar Hellmacs stays on the
classic mode and says so.

**Requirements beyond Java's:** `unzip` (server installs), network access on first `sync`
(about 90MB for kotlin-language-server, 35MB for clojure-lsp), and for Clojure a REPL tool.
`bin/hellmacs doctor` checks each.

## Command line

| Command | What it does |
|---|---|
| `bin/hellmacs sync` | Install what's declared and rewrite the profile. Run after changing your `hellmacs!` block, a `packages.el` or a module's `autoload.el` (also `C-c h s` inside Emacs). |
| `bin/hellmacs upgrade` | `git pull` Hellmacs, update every package without a `:pin`, then sync. `--packages` updates only packages. |
| `bin/hellmacs lock` | Record the exact commit of every package in `~/.config/hellmacs/packages.lock.eld`. Later installs use those commits. Commit it with your config to reproduce it elsewhere. |
| `bin/hellmacs gc` | Delete installed packages nothing declares anymore (`-n` to only list them). |
| `bin/hellmacs env` | Save your shell environment for Emacs (`--clear` removes it). Re-run it after changing your shell setup. |
| `bin/hellmacs doctor` | Check Emacs, tools and your config for problems. |
| `bin/hellmacs test` | Run Hellmacs' own test suites (`test/`), in temporary directories. |

Every command takes `--profile NAME` first (for example `bin/hellmacs --profile work sync`).
A profile is a completely separate config with its own packages and history, in
`~/.config/hellmacs-NAME/` and the matching `~/.local/share`, `~/.cache` and
`~/.local/state` directories. Start Emacs on it with
`emacs --init-directory <dir> --profile NAME`.

If you forget to sync, Hellmacs warns at startup and carries on the slow way. It also works
without ever running `bin/hellmacs`: the first launch then installs everything inside the editor.

## Your config

Your config, created by `install` (or `C-c h u` / `M-x hellmacs-init-user-dir` inside Emacs),
starts as copies of the files in `static/`:

- `init.el` runs before any module. Its `hellmacs!` block chooses modules and their flags:

  ```elisp
  (hellmacs! :ui theme
             :editor undo
             :completion vertico (corfu +tab)
             :config default)
  ```
- `packages.el` declares extra packages with `package!` (or `:disable`s a module's).
- `config.el` runs after every module: everything else.

All are optional; without them Hellmacs runs with the defaults in `static/init.example.el`.

## Keys

Stock Emacs keys work as usual. Hellmacs' own commands live under `C-c`:

| Key | Command |
|---|---|
| `C-c h s` | Return to the Altar (the startup screen) |
| `C-c h f` | Forge: find a file in the current project (picks a project first outside one) |
| `C-c h c` | Reap: run the garbage collector now and report memory |
| `C-c h r` | Crucible: hot-swap changed classes into a debugged JVM, or reload into the Clojure REPL (CIDER) |
| `C-c h R` / `C-c h S` | Reload the config / sync packages |
| `C-c h u` / `C-c h v` / `C-c h m` | Your config dir / the Hellmacs dir / enabled modules |
| `C-c f`, `C-c b`, `C-c s`, `C-c w`, `C-c q` | File, buffer, search, window, quit groups |
| `C-c d` | Debug (`:tools debugger`): `d` start, `b` breakpoint, `n` `i` `o` `c` step (then plain `n` `i` `o` `c` repeat), `e` evaluate, `t` debug the test at point |
| `C-c l` / `C-c ! n` `p` | Language server actions (`:tools lsp`) / next and previous diagnostic |
| `C-x g` | Magit status (`:tools magit`) |

which-key shows these after a short pause on any prefix. The same `C-c h` map is
`hellmacs-prefix-map`, which you can also bind yourself, e.g.
`(keymap-global-set "<f12>" hellmacs-prefix-map)`.

To tone the look down, set any of these in your `init.el`:
- `(setq hellmacs-theme 'modus-vivendi)` uses another theme (`nil` loads none).
- `(setq hellmacs-splash-enable nil)` starts on `*scratch*` instead of the Altar.
- `(setq hellmacs-ux-enable nil)` keeps Emacs' own quit prompt and error messages.

## Modules

A module is a directory `modules/<group>/<name>/`, written `:group name`. Every file in it is
optional:

| File | Purpose |
|---|---|
| `packages.el` | `package!` declarations: what to install. Nothing else. |
| `autoload.el` | Commands and helpers other files call |
| `init.el` | Runs before any module's `config.el` |
| `config.el` | The configuration itself, with `use-package` |

`bin/hellmacs sync` reads every enabled module's `packages.el` (then yours) and installs what's
missing. At startup Hellmacs activates those packages from the synced profile, then loads each
module's `init.el`, then each `config.el`, in `hellmacs!` order.
Inside a module, `(modulep! +flag)` tests its own flags; `(modulep! :group name)` tests
whether another module is enabled.

To add one, copy `static/module-template/` to `modules/<group>/<name>/` -- or to
`~/.config/hellmacs/modules/<group>/<name>/` for a private module, which also overrides a
built-in module of the same name -- and add it to your `hellmacs!` block. See the template's
comments for the conventions every module follows.

## License

Hellmacs is free and open-source software licensed under the **GNU General Public License v3.0 (GPL-3.0-or-later)**.

Copyright (C) 2026 petrolal <petrolalucas@gmail.com>

Under the terms of the GNU GPLv3:
- **Copyleft / Open Source Requirement:** Anyone who modifies, forks, or distributes Hellmacs (or derivative works) **must** release their changes as open source under the GNU GPL v3.0 license.
- **Attribution / Name Protection:** All copyright notices and author attributions to `petrolal` must be preserved in all copies and substantial portions of the software.
- See the full license in [`LICENSE`](LICENSE).

