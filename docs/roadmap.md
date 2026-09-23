# Hellmacs architecture roadmap

This roadmap covers moving Hellmacs from a flat list of `require`d files to a
framework modeled on Doom Emacs' core (`doomemacs/core`, v2.2 → v3 split). The
module system, config separation, sync-time generated init file, and CLI all
come from Doom. The package layer is new: Doom still uses straight.el
(`lisp/doom-elpaca.el` is an empty `;; TODO`), and Hellmacs stays on Elpaca.

## How Doom's core works (reference)

Doom's core rests on six ideas.

1. **The framework and the user's config are separate.**
   - `doom-emacs-dir` holds the framework and is updated with git.
   - `doom-user-dir` (`$DOOMDIR`, `~/.config/doom`) holds the user's
     `init.el` (a `doom!` block that enables modules), `packages.el`, and
     `config.el`.
   - State goes in XDG data, cache, and state dirs, with one folder per
     profile.
   - `user-emacs-directory` is re-pointed at the cache dir. Most packages build
     their state paths from it, so this puts their clutter there with no
     per-package `setq`.
2. **Modules are directories.**
   - Each module lives at `modules/<group>/<name>/` and is named `:group name`.
   - A module holds `packages.el` (declarations only, read by the CLI),
     `init.el` (runs early), `config.el` (interactive sessions), `autoload.el`
     or `autoload/*.el` (lazily loaded functions), and `cli.el`.
   - Modules take flags, as in `(corfu +orderless)`. `modulep!` queries modules
     and flags at runtime.
   - `:depth` sets the load order. Core and the user config are virtual modules.
3. **`package!` only declares a package.** It records the recipe, `:pin`,
   `:disable`, and `:built-in 'prefer`. Nothing is installed at startup. The
   `doom sync` command installs packages.
4. **A generated profile init file is where the speed comes from.**
   - `doom sync` writes numbered fragments into `init.d/` and concatenates them
     into one file:
     - the precomputed `load-path` and `auto-mode-alist`
     - core, module, and package autoloads, in dependency order
     - the module state, cached in symbol plists so `modulep!` stays O(1)
     - hard-coded `load` calls for every module's `init.el` and `config.el`, in
       depth order, wrapped in before/after hooks
   - An advice on `startup--load-user-init-file` loads that file instead of
     `init.el`. Startup does no discovery work.
5. **The lifecycle has named stages and lazy hooks.**
   - Startup runs in this order: `early-init.el`, then `doom.el`, then
     `doom-initialize`, then the generated init, then `doom-startup-functions`,
     then `doom-finalize`.
   - `doom-first-{input,file,buffer}-hook` fire once, on the first keypress,
     file, or buffer.
   - Packages can also load incrementally while Emacs is idle.
   - `doom-context` records the session mode: startup, cli, emacs, module,
     init, or config.
6. **The `bin/doom` CLI is written in elisp** and runs through `doomscript`.
   Its commands are defined with `defcli!` and include `sync`, `doctor`,
   `upgrade`, `gc`, `env`, `profile`, and `install`.

Doom also ships a standard library (`after!`, `add-hook!`, `setq-hook!`,
`defadvice!`, `cmd!`, `load!`, `quiet!`, `letf!`, `defer-until!`) and a set of
opinionated defaults in `doom-emacs.el`.

## Where Hellmacs starts

- `early-init.el` sets up the directories, tunes GC and file handlers, and
  configures native-comp.
- `init.el` `require`s a fixed `hellmacs-modules` list.
- `core/` handles the GC lifecycle, keeps state files inside `var/` and `etc/`,
  and bootstraps Elpaca.
- There are six single-file modules. Each uses `use-package :ensure t`.

## Phases

Each phase can ship on its own. Hellmacs doesn't copy Doom line for line: about
half of Doom's complexity is v2 backward compatibility and straight.el.

### Phase 0: Foundations

- [ ] First git commit.
- [x] `core/hellmacs-lib.el`: `after!`, `add-hook!`, `remove-hook!`,
      `setq-hook!`, `defadvice!`, `cmd!`, `hellmacs-log`, and
      `hellmacs-run-hooks`.
- [x] `hellmacs-first-{input,file,buffer}-hook` and `hellmacs-after-init-hook`.
- [x] `hellmacs-context` (`startup`, `emacs`, `cli`, `reload`, ...).
- [x] Use the new hooks in core: `savehist`, `recentf`, and `save-place` now
      start lazily.

The `!` macros are user-facing sugar, so they keep Doom's unprefixed names.
Every function and variable uses the `hellmacs-` prefix.

### Phase 1: Separate the framework from the user config

- [ ] `hellmacs-user-dir`: the first match among `$HELLMACSDIR`,
      `~/.config/hellmacs/`, and `~/.hellmacs.d/`. It holds `init.el` (the
      module list), `packages.el`, and `config.el`.
- [ ] `static/*.example.el` templates for the user dir.
- [ ] Move `var/` and `etc/` to XDG data, cache, and state dirs. Keep
      `hellmacs-var-dir` and `hellmacs-etc-dir` as obsolete aliases for a while.
- [ ] Re-point `user-emacs-directory` at the cache dir and remove most of the
      manual path `setq`s in `hellmacs-core.el`.

### Phase 2: Module system

- [ ] Change the layout to `modules/<group>/<name>/{packages,init,config,autoload}.el`,
      for example `:ui theme`, `:editor evil`, `:completion vertico`, and
      `:config keybinds`. Later: `:lang java`, `:lang clojure`, and
      `:tools lsp`.
- [ ] Add `hellmacs!` (the `doom!` equivalent), with flags, a module table,
      `modulep!`, and `:depth` ordering.
- [ ] Add `package!`, which is declarative only. It records recipe, `:pin`, and
      `:disable`, and maps to an Elpaca order.
- [ ] Modules keep `use-package` for configuration, with `:ensure nil`, so
      installing a package is separate from configuring it.

### Phase 3: Sync and the generated init file (the Elpaca adaptation)

- [ ] `hellmacs-sync` collects every `package!` declaration from the enabled
      modules and the user's `packages.el`, queues the `elpaca` orders, and
      runs `elpaca-wait`.
- [ ] Write `$DATA/hellmacs/<profile>/init.el`. It holds the precomputed
      `load-path`, the concatenated autoloads (ordered by Elpaca's dependency
      data), the module table, and the ordered `load` calls.
- [ ] At startup, load the generated file if it exists and skip Elpaca's queue.
      If it doesn't exist, use today's live Elpaca path, so a fresh clone still
      boots.
- [ ] Implement `:pin` with `elpaca-write-lock-file` and `:ref`, and add a
      `hellmacs lock` command.

### Phase 4: `bin/hellmacs` CLI

- [ ] A shell wrapper that runs `emacs --batch -l early-init.el` and dispatches
      to a small set of commands.
- [ ] Commands:
  - `sync`
  - `doctor`, which checks for java, JDTLS, clojure-lsp, rg, and fd
  - `upgrade`
  - `gc`
  - `env`, which snapshots the shell's `PATH` and other variables. JVM
    toolchains depend on this.
- [ ] Don't add a `defcli!` framework until there are enough commands to need
      one.

### Phase 5: Optional and later

- [ ] Profiles (`--profile`).
- [ ] Incremental loading of packages while Emacs is idle.
- [ ] `gcmh` in place of the hand-rolled idle-GC timer.
- [ ] Doom's extra `early-init` tweaks:
  - overriding `display-startup-screen`
  - deferring `tool-bar-setup`
  - hiding the mode-line during startup
  - trimming `file-name-handler-alist` while keeping the gzip handler

### Out of scope

- straight.el
- Doom's `compat` module and v2 deprecation shims
- The docs system (`doom-docs.el`)
- Windows-specific hacks
- The full `defcli!` framework
- The `:doom` and `:user` virtual modules. Depth numbers are enough.

## Risks

- **Phase 3 is the hard part.** Elpaca is asynchronous, so the generated file
  can only be written after `elpaca-wait` returns and every build step has
  finished. Autoload order must follow Elpaca's dependency graph.
- **The XDG move reinstalls every package once.**
