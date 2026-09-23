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

Hellmacs fuses the vicious, split-second modal lethality of `evil-mode` with the
industrial-grade machinery of the JVM. Whether you're slinging Clojure s-expressions,
tearing through raw Java bytecode, or orchestrating massive enterprise daemons, Hellmacs
turns your editor into a high-octane siege engine.

- **Flawless LSP Annihilation** *(planned)* — direct, lightning-fast integration with
  Eclipse JDTLS, Clojure LSP, and Kotlin engines. Zero lag, pure carnage.
- **REPL Driven Damnation** *(planned)* — hot-reload code directly into the burning core
  of running JVM instances with zero downtime.
- **Aggressive Garbage Execution** — custom-tuned, low-pause GC hooks and
  native-compilation flags that choke Emacs's own startup latency before it draws breath.
  This part's already lit; see [`early-init.el`](early-init.el) and
  [`core/hellmacs-core.el`](core/hellmacs-core.el).
- **The Nether-Stack** — built on a razor-sharp modern foundation (`elpaca` + `vertico`
  + `corfu` + `evil`), wrapped in a pitch-black, blood-red `modus-themes` aesthetic.

Lock in. Jack into the daemon. Let the bytecode burn.

## Current stack

The JVM warfare above — JDTLS, Clojure LSP, Kotlin, CIDER-driven REPLs — is the target.
What's actually forged and working right now is the foundation it's built on:

- **Package manager:** [Elpaca](https://github.com/progfolio/elpaca) (async, git-based, reproducible)
- **Modal editing:** `evil` + `evil-collection`
- **Completion:** `vertico` + `consult` + `marginalia` + `orderless` + `corfu`
- **Keybindings:** `general.el`, Space as leader, `<leader> h` for Hellmacs meta/help
- **Undo:** `undo-fu` + `undo-fu-session`
- **Theme:** `modus-themes` (built into Emacs 28+)

## Directory layout

```
hellmacs/
├── early-init.el            # Pre-frame boot: GC tuning, dir layout, UI chrome suppression
├── init.el                  # Bootstrap orchestrator: load-path, package manager, module loading
├── core/                    # Engine internals -- no editing-style opinions
│   ├── hellmacs-lib.el          # Macros (after!, add-hook!, setq-hook!, defadvice!, cmd!), session context
│   ├── hellmacs-core.el         # Startup lifecycle + first-input/file/buffer hooks, GC, XDG dir isolation, defaults
│   └── hellmacs-packages.el     # Elpaca bootstrap + use-package integration
├── modules/                 # User-facing feature stack, each independently toggleable
│   ├── hellmacs-ui.el           # Theme, frame, mode-line
│   ├── hellmacs-editor.el       # Undo system, editing defaults
│   ├── hellmacs-keybinds.el     # Leader-key framework + which-key (SPC h, SPC q)
│   ├── hellmacs-evil.el         # Modal editing (SPC w)
│   ├── hellmacs-completion.el   # Minibuffer + in-buffer completion (SPC f, SPC b, SPC s)
│   └── hellmacs-template.el     # Scaffold for writing a new module -- not loaded by default
├── docs/
│   └── roadmap.md               # Plan for the Doom-style module/sync/CLI architecture
└── static/                  # Starter init.el / config.el copied into your user dir
```

Nothing Hellmacs or its packages write at runtime lands in this checkout:

| What | Where | Safe to delete? |
|---|---|---|
| Your config (`init.el`, `config.el`, `custom.el`) | `$HELLMACSDIR`, else `~/.config/hellmacs/`, else `~/.hellmacs.d/` | No -- it's yours |
| Installed packages (Elpaca) | `$XDG_DATA_HOME/hellmacs/` (`~/.local/share/hellmacs/`) | Yes, but everything reinstalls |
| Native-comp output, package caches | `$XDG_CACHE_HOME/hellmacs/` (`~/.cache/hellmacs/`) | Yes, any time |
| History, recent files, bookmarks, undo, backups | `$XDG_STATE_HOME/hellmacs/` (`~/.local/state/hellmacs/`) | Yes, but that history is gone |

`core/` has no opinions about *how* you edit -- it just makes stock Emacs fast and keeps its
state in the directories above instead of scattering it across `~`. `modules/` is where the actual
editing experience is assembled, one file per feature, each independently removable by deleting
its symbol from `hellmacs-modules` in your own `init.el`. A future `hellmacs-jvm.el` (JDTLS/Clojure
LSP/CIDER) slots in the same way once it exists.

## Installing

```sh
git clone <this-repo> ~/.config/emacs   # or wherever you point $HOME/.emacs.d
emacs
```

First launch bootstraps Elpaca and installs every package declared across `modules/`; this
requires network access and takes a minute or two. Subsequent launches are local-only.

Then create your own config with `SPC h u` (or `M-x hellmacs-init-user-dir`). It copies
starter `init.el` and `config.el` files from `static/` into `~/.config/hellmacs/`:

- `init.el` runs before any module: choose modules (`hellmacs-modules`) and set early variables.
- `config.el` runs after every module: everything else.

Both are optional; without them Hellmacs runs with its defaults.

## Adding a module

Copy `modules/hellmacs-template.el` to `modules/hellmacs-<name>.el`, then add `hellmacs-<name>`
to `hellmacs-modules` in your user `init.el`. See the comments in the template for the conventions every
module follows (naming, `use-package` laziness, leader-group ownership).

## License

GPLv3 — see [`LICENSE`](LICENSE).
