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

- **Flawless LSP Annihilation** *(planned)* — direct, lightning-fast integration with
  Eclipse JDTLS, Clojure LSP, and Kotlin engines. Zero lag, pure carnage.
- **REPL Driven Damnation** *(planned)* — hot-reload code directly into the burning core
  of running JVM instances with zero downtime.
- **Aggressive Garbage Execution** — custom-tuned, low-pause GC hooks and
  native-compilation flags that choke Emacs's own startup latency before it draws breath.
  This part's already lit; see [`early-init.el`](early-init.el) and
  [`core/hellmacs-core.el`](core/hellmacs-core.el).
- **The Nether-Stack** — built on a razor-sharp modern foundation (`elpaca` + `vertico`
  + `corfu`), wrapped in a pitch-black, blood-red `modus-themes` aesthetic.

Lock in. Jack into the daemon. Let the bytecode burn.

## Current stack

The JVM warfare above — JDTLS, Clojure LSP, Kotlin, CIDER-driven REPLs — is the target.
What's actually forged and working right now is the foundation it's built on:

- **Package manager:** [Elpaca](https://github.com/progfolio/elpaca) (async, git-based, reproducible)
- **Completion:** `vertico` + `consult` + `marginalia` + `orderless` + `corfu`
- **Keybindings:** stock Emacs keys, no Vim emulation. Hellmacs' own commands live under
  `C-c` (`C-c h` Hellmacs, `C-c f` file, `C-c b` buffer, `C-c s` search, `C-c w` window),
  with `which-key` showing what follows any prefix
- **Undo:** built-in `undo` / `undo-redo`, plus `undo-fu-session` to keep undo history across restarts
- **Theme:** `modus-themes` (built into Emacs 28+)

## Directory layout

```
hellmacs/
├── early-init.el            # Pre-frame boot: GC tuning, dir layout, UI chrome suppression
├── init.el                  # Bootstrap orchestrator: core, package manager, modules, user config
├── core/                    # Engine internals -- no editing-style opinions
│   ├── hellmacs-lib.el          # Macros (after!, add-hook!, setq-hook!, defadvice!, cmd!), session context
│   ├── hellmacs-core.el         # Startup lifecycle + first-input/file/buffer hooks, GC, XDG dir isolation, defaults
│   ├── hellmacs-packages.el     # Elpaca bootstrap + use-package integration
│   ├── hellmacs-keybinds.el     # The C-c leader: `hellmacs-leader-def'
│   └── hellmacs-modules.el      # Module system: `hellmacs!', `modulep!', `package!'
├── modules/<group>/<name>/  # User-facing features, enabled with `hellmacs!'
│   ├── ui/theme/                # modus-themes, cursor, line numbers
│   ├── editor/undo/             # Persistent undo history (undo-fu-session)
│   ├── completion/vertico/      # Minibuffer completion + consult (C-c f, C-c b, C-c s)
│   ├── completion/corfu/        # In-buffer completion popup (+tab: TAB completes)
│   └── config/default/          # Default keys: C-c h, C-c q, C-c w; which-key
├── docs/
│   └── roadmap.md               # Plan for the Doom-style module/sync/CLI architecture
└── static/                  # Starter init.el / packages.el / config.el, and a module template
```

Nothing Hellmacs or its packages write at runtime lands in this checkout:

| What | Where | Safe to delete? |
|---|---|---|
| Your config (`init.el`, `packages.el`, `config.el`, `custom.el`, private `modules/`) | `$HELLMACSDIR`, else `~/.config/hellmacs/`, else `~/.hellmacs.d/` | No -- it's yours |
| Installed packages (Elpaca) | `$XDG_DATA_HOME/hellmacs/` (`~/.local/share/hellmacs/`) | Yes, but everything reinstalls |
| Native-comp output, package caches | `$XDG_CACHE_HOME/hellmacs/` (`~/.cache/hellmacs/`) | Yes, any time |
| History, recent files, bookmarks, undo, backups | `$XDG_STATE_HOME/hellmacs/` (`~/.local/state/hellmacs/`) | Yes, but that history is gone |

`core/` has no opinions about *how* you edit -- it just makes stock Emacs fast and keeps its
state in the directories above instead of scattering it across `~`. `modules/` is where the actual
editing experience is assembled, one directory per feature, each enabled or disabled from the
`hellmacs!` block in your own `init.el`. A future `:lang java` / `:lang clojure` / `:tools lsp`
(JDTLS/Clojure LSP/CIDER) slots in the same way once it exists.

## Installing

```sh
git clone <this-repo> ~/.config/emacs   # or wherever you point $HOME/.emacs.d
emacs
```

First launch bootstraps Elpaca and installs every package declared across `modules/`; this
requires network access and takes a minute or two. Subsequent launches are local-only.

Then create your own config with `C-c h u` (or `M-x hellmacs-init-user-dir`). It copies
starter files from `static/` into `~/.config/hellmacs/`:

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

## Modules

A module is a directory `modules/<group>/<name>/`, written `:group name`. Every file in it is
optional:

| File | Purpose |
|---|---|
| `packages.el` | `package!` declarations: what to install. Nothing else. |
| `autoload.el` | Commands and helpers other files call |
| `init.el` | Runs before any module's `config.el` |
| `config.el` | The configuration itself, with `use-package` |

At startup Hellmacs reads every enabled module's `packages.el` (then yours), installs what's
missing, then loads each module's `init.el`, then each `config.el`, in `hellmacs!` order.
Inside a module, `(modulep! +flag)` tests its own flags; `(modulep! :group name)` tests
whether another module is enabled.

To add one, copy `static/module-template/` to `modules/<group>/<name>/` -- or to
`~/.config/hellmacs/modules/<group>/<name>/` for a private module, which also overrides a
built-in module of the same name -- and add it to your `hellmacs!` block. See the template's
comments for the conventions every module follows.

## License

GPLv3 — see [`LICENSE`](LICENSE).
