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

## Keybinding policy: Emacs defaults, not Vim

Hellmacs uses Emacs' default keybindings. It is not a Vim or Neovim emulation:
there is no `evil-mode`, no modal editing, and no `SPC` leader.

- **Stock bindings stay as they are.** `C-x C-f`, `C-x b`, `C-s`, `M-x`,
  `C-g` and so on keep their normal meaning. Hellmacs never rebinds a default
  key to something else.
- **Hellmacs' own commands live under `C-c`,** the prefix Emacs reserves for
  users. This is also Doom's layout for non-evil users:
  - `C-c h`: Hellmacs meta (reload, visit dirs, list modules)
  - `C-c f`: file, `C-c b`: buffer, `C-c s`: search, `C-c w`: window
  - `C-c l`: the local leader, for commands specific to the current major mode
    (e.g. JVM language modes)
- **Packages improve default commands instead of adding new keys.** For example,
  `consult-buffer` is remapped onto `C-x b` and `consult-line` onto `M-s l`.
  Emacs muscle memory keeps working.
- **which-key stays.** It shows what follows any prefix, including `C-c`,
  `C-x` and `C-h`.

Doom supports both styles (an `:editor evil` module plus the `C-c` fallback).
Hellmacs only supports the Emacs style. Users who want Vim bindings can add
`evil` themselves in their own `config.el`, but no module ships it.

## Where Hellmacs starts

- `early-init.el` sets up the directories, tunes GC and file handlers, and
  configures native-comp.
- `init.el` `require`s a fixed `hellmacs-modules` list.
- `core/` handles the GC lifecycle, keeps state files inside `var/` and `etc/`,
  and bootstraps Elpaca.
- There are six single-file modules. Each uses `use-package :ensure t`.
- Keybindings were Vim-style (`evil`, `evil-collection`, a `SPC` leader
  through `general.el`). That conflicted with the keybinding policy above and
  was removed in Phase 1.5.

## Phases

Each phase can ship on its own. Hellmacs doesn't copy Doom line for line: about
half of Doom's complexity is v2 backward compatibility and straight.el.

### Phase 0: Foundations

- [ ] First git commit (waiting for approval).
- [x] `core/hellmacs-lib.el`: `after!`, `add-hook!`, `remove-hook!`,
      `setq-hook!`, `defadvice!`, `cmd!`, `hellmacs-log`, and
      `hellmacs-run-hooks`.
- [x] `hellmacs-first-{input,file,buffer}-hook` and `hellmacs-after-init-hook`.
- [x] `hellmacs-context` (`startup`, `emacs`, `cli`, `reload`, ...).
- [x] Use the new hooks in core: `savehist`, `recentf`, and `save-place` now
      start lazily.

The `!` macros are user-facing sugar, so they keep Doom's unprefixed names.
Every function and variable uses the `hellmacs-` prefix.

### Phase 1: Separate the framework from the user config (done)

- [x] `hellmacs-user-dir`: the first match among `$HELLMACSDIR`,
      `~/.config/hellmacs/`, and `~/.hellmacs.d/`, defaulting to
      `~/.config/hellmacs/`. It holds `init.el` (loaded before modules; sets
      `hellmacs-modules`), `config.el` (loaded after modules), and
      `custom.el`. Errors in these files show as warnings and don't stop
      startup.
- [x] `static/{init,config}.example.el` templates, copied by
      `hellmacs-init-user-dir` (`C-c h u` offers to run it).
- [x] Packages go to `$XDG_DATA_HOME/hellmacs`, native-comp output and caches
      to `$XDG_CACHE_HOME/hellmacs`, and history, backups, and undo to
      `$XDG_STATE_HOME/hellmacs`. `hellmacs-var-dir` and `hellmacs-etc-dir`
      remain as obsolete aliases.
- [x] `user-emacs-directory` points at the cache dir. Unlike the original plan,
      the explicit path `setq`s stay: they're all state (history, bookmarks),
      and state must not land in a dir that's meant to be disposable. Doom does
      the same.

`packages.el` in the user dir is deferred to Phase 2, where `package!` exists.
Until then, extra packages go in `config.el` via `use-package`.

### Phase 1.5: Switch to Emacs default keybindings (done)

- [x] Removed `modules/hellmacs-evil.el` (`evil`, `evil-collection`).
- [x] `hellmacs-keybinds`: `hellmacs-leader-def` now binds `KEY DEF` pairs into
      `mode-specific-map` (Emacs' own `C-c` map), so other `C-c` bindings keep
      working. `general.el` is gone; `keymap-set` covers it. A `(LABEL .
      COMMAND)` definition gives which-key a label, and a string labels a
      prefix group.
- [x] `C-c w` is built from built-in window commands: split, delete,
      maximize, balance, `windmove` in Emacs directions (`b`/`f`/`p`/`n`),
      and `winner` undo/redo. `C-c q r` restarts Emacs.
- [x] `hellmacs-completion`: consult remaps `switch-to-buffer`, `yank-pop`,
      `goto-line`, `imenu`, `bookmark-jump` and related commands, so `C-x b`,
      `M-y`, `M-g g`, etc. get the consult versions. It adds `M-s l` / `M-s r`
      / `M-s f` and fills the `C-c f`, `C-c b` and `C-c s` groups.
- [x] `hellmacs-editor`: `undo-fu` is dropped in favor of Emacs' own `undo` /
      `undo-redo`. `undo-fu-session` stays.
- [x] README, the module template and the `static/` templates are updated.
      Hellmacs now requires Emacs 29.1+ (checked at startup in `init.el`).

The `C-c l` local leader has no bindings yet. It arrives with the first
language module.

### Phase 2: Module system

- [ ] Change the layout to `modules/<group>/<name>/{packages,init,config,autoload}.el`,
      for example `:ui theme`, `:editor undo`, `:completion vertico`, and
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
