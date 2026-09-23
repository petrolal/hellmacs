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
- **New prefixes follow the same rules** (Phase 6): `C-c l` for LSP,
  `C-c d` for debugging, and `C-c !` for diagnostics, the last only inside
  `lsp-mode-map`, as minor-mode keys should be.
- **TAB keeps its stock behavior.** It indents; `C-M-i` completes. Making TAB
  also complete is opt-in, with the `+tab` flag of `:completion corfu`.

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

- [x] First git commit.
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

### Phase 2: Module system (done)

- [x] New layout, `modules/<group>/<name>/{packages,autoload,init,config}.el`:
      `:ui theme`, `:editor undo`, `:completion vertico`, `:completion corfu`
      and `:config default`. Later: `:lang java`, `:lang clojure` and
      `:tools lsp`.
- [x] `hellmacs!` (the `doom!` equivalent) in the user's init.el, with +flags
      and `:depth N`. With no user init.el (or no `hellmacs!` in it),
      `static/init.example.el` supplies the defaults. Unknown modules warn and
      are skipped.
- [x] `modulep!`: `(modulep! :group name +flag -flag)`, or `(modulep! +flag)`
      inside a module (resolved when the file loads).
- [x] Private modules in `$HELLMACSDIR/modules/` take priority over built-in
      modules of the same name (`hellmacs-module-load-path`).
- [x] `package!` only records a declaration (`:recipe`, `:pin` → Elpaca
      `:ref`, `:built-in` t/`'prefer`, `:disable`). Later declarations merge
      over earlier ones, so the user's `packages.el` (read last) can override a
      module's. `:disable` also turns that package's `use-package` blocks into
      no-ops.
- [x] `use-package-always-ensure` is now nil: modules declare with `package!`
      and configure with `use-package`.
- [x] `hellmacs-leader-def` moved to `core/hellmacs-keybinds.el`, so it exists
      regardless of which modules are enabled.
- [x] Module template moved to `static/module-template/`; the user starter
      files now include `packages.el`.

For now, packages are still installed at startup: step 2 of
`hellmacs-modules-startup` queues every declared package with Elpaca and
waits. `autoload.el` is loaded eagerly; its `;;;###autoload` cookies
start working once Phase 3 generates loaddefs.

### Phase 3: Sync and the generated profile (done)

- [x] `hellmacs-sync` (`core/hellmacs-sync.el`) reads the `hellmacs!` block and
      every `packages.el`, queues the Elpaca orders, runs `elpaca-wait`, and
      fails loudly if any package didn't build.
- [x] It writes a profile to `$XDG_DATA_HOME/hellmacs/profiles/default/`:
  - `profile.eld`: the build directories and autoload files of every declared
    package and its dependencies, in dependency order, plus
    `hellmacs-packages`, the module list, and the facts the profile depends
    on (see below).
  - `module-autoloads.el`: real autoloads generated from the
    `;;;###autoload` cookies in modules' `autoload.el`.
- [x] Startup replays an up-to-date profile without loading Elpaca at all
      (about 0.03s, versus 0.09s on the live path). Elpaca moved to
      `core/hellmacs-elpaca.el`, loaded only by a sync or by the live path.
- [x] The profile is out of date when the Emacs version, the enabled
      modules/flags/paths, or the mtime of any involved `packages.el` or
      `autoload.el` changes, or when a recorded build directory is gone. Startup
      then warns and falls back to the live Elpaca path, so a forgotten sync
      only costs speed. With no profile at all (a fresh clone), the live path
      runs silently.
- [x] Startup-finished work (GC restore, `custom-file`, `hellmacs-finalize`)
      hangs off `hellmacs--packages-ready-hook`, fired by `after-init-hook`
      (synced) or `elpaca-after-init-hook` (live).
- [x] `bin/hellmacs sync` (batch) and `M-x hellmacs-sync` / `C-c h s`
      (in-session). This pulls the Phase 4 `sync` command forward.
- [x] On a synced startup, `use-package :ensure` warns instead of silently
      falling through to package.el; declare packages with `package!`.
- [x] Fixed the fresh-install hang. When several packages discover the same
      undeclared dependency at once (`compat`, for vertico, consult, corfu,
      marginalia and orderless), Elpaca starts building it twice. The second
      build fails, and the packages waiting on it stay blocked forever, so
      `elpaca-wait` never returns. `core/packages.el` (read before any
      module, like Doom's `lisp/packages.el`) now declares `compat` up front.
      A fresh sync takes about 12s instead of hanging. As a safety net,
      `hellmacs--elpaca-wait` gives up once only blocked packages remain and
      nothing has changed for 30s, and the sync then names the failed
      packages. This is likely an upstream Elpaca bug and worth reporting.

Differences from the original plan:
- The profile is data (`profile.eld`) plus one generated autoloads file, not
  one concatenated init file. Each package's own autoloads file is loaded
  rather than inlined, which avoids rewriting their `load-file-name`-relative
  forms. At 7-10 packages, the extra file loads cost nothing measurable.
- Module `init.el`/`config.el` loads are not baked into the profile. They
  are still discovered at startup (a handful of `file-exists-p` calls), so
  editing or adding those files never needs a sync.
- `:pin` already maps to Elpaca's `:ref` (Phase 2). A lock file
  (`elpaca-write-lock-file`) moves to Phase 4, where `upgrade` makes it
  meaningful.

### Phase 4: `bin/hellmacs` CLI (done)

- [x] `bin/hellmacs` is a small shell wrapper that runs
      `emacs --batch -l early-init.el` and calls `hellmacs-cli-main`
      (`core/hellmacs-cli.el`). Each command is a `hellmacs-cli-COMMAND`
      function, so there's no `defcli!` framework. Commands exit 0 on success
      and 1 on failure.
- [x] `install [--env] [--no-config]`: creates the user config from
      `static/`, syncs, optionally saves the environment, then runs `doctor`.
      `hellmacs-init-user-dir` moved into core so it works without
      `:config default`.
- [x] `sync` (from Phase 3).
- [x] `upgrade [--packages]`:
  - First it runs `git pull --ff-only` on Hellmacs. This is skipped when the
    checkout has uncommitted changes or no upstream.
  - Then it updates packages in a fresh Emacs, so the new code does the
    update.
  - Every package without a `:pin` is fetched and merged, the profile is
    re-synced, and the lock file is rewritten if there is one.
  - A checkout left on a detached HEAD by a lock install is put back on its
    branch first. Otherwise Elpaca's update fails, because there's no
    upstream (`@{u}`).
- [x] `lock`: syncs, then writes the exact commit of every package to
      `$HELLMACSDIR/packages.lock.eld`, next to the config so they can be
      versioned together. When the file exists, every install uses it
      (`elpaca-lock-file`). Verified by locking an older vertico commit and
      reinstalling.
- [x] `gc [-n]`: syncs, then deletes package build and source directories
      nothing declares anymore, such as the old evil stack.
- [x] `env [--clear]`: saves the environment `bin/hellmacs` was run with,
      minus session variables (DISPLAY, SSH_AUTH_SOCK, TERM, ...), to
      `$XDG_DATA_HOME/hellmacs/env`. Interactive startup prepends it to
      `process-environment` and updates `exec-path`.
- [x] `doctor`:
  - checks the Emacs version, dev builds, and native compilation
  - checks for git (required)
  - checks for rg, fd, java, jdtls, and clojure-lsp (optional, with what each
    is for)
  - reports the user config, modules, sync state, lock, and env file
  - flags the leftover `var/` and `etc/` from before Phase 1

### Phase 5: Profiles, GC, incremental loading, startup tweaks (done)

- [x] **Profiles.** Start with `emacs --profile NAME` or `HELLMACS_PROFILE=NAME`;
      the CLI takes `bin/hellmacs --profile NAME ...`.
  - A named profile gets its own copy of every directory:
    `~/.config/hellmacs-NAME/`, `~/.local/share/hellmacs-NAME/`, and so on,
    which covers config, packages, synced profile, env file, lock, caches and
    history.
  - `--profile` is consumed through `command-switch-alist`, so Emacs doesn't
    open it as a file. Names are limited to `[A-Za-z0-9_-]`.
  - The default profile's paths are unchanged.
  - Unlike Doom, there's no `profiles.el` registry: the name alone decides
    the directories.
- [x] **Incremental loading.** `hellmacs-load-incrementally` queues features,
      and a `:defer-incrementally` keyword does the same from `use-package`.
      Queued features load one at a time on idle timers, starting 2s after
      startup and then every 0.75s. consult uses it, so the first `C-x b` no
      longer loads it.
- [x] **`gcmh`** (declared in `core/packages.el`) replaces the hand-rolled
      idle-GC timer and minibuffer GC hooks. It starts at the first real
      buffer with an `auto` idle delay and a 64MB high threshold, as in Doom.
      It's skipped on igc builds, and it can be disabled with
      `(package! gcmh :disable t)`.
- [x] **Startup tweaks from Doom:**
  - `file-name-handler-alist` is trimmed at startup but keeps the gzip
    handler when Emacs' own Lisp is compressed. This Emacs ships
    `.el.gz`, and the old code dropped the handler.
  - It's restored for files opened from the command line, and merged back
    after startup instead of overwritten. The trimming is skipped for the
    daemon.
  - `display-startup-screen` and `display-startup-echo-area-message` are
    overridden. This removes the "For information about GNU Emacs" message
    that the `inhibit-startup-echo-area-message` setting didn't.
  - A broken `native-compile` feature (no libgccjit) is hidden.
  - Other settings: `auto-mode-case-fold` nil, `ad-redefinition-action`
    accept, `read-process-output-max` 64KB, no missing-lexbind-cookie
    warnings for third-party packages, and `DEBUG=1` enables debug mode.
  - Skipped on purpose: deferring `tool-bar-setup` and hiding the mode-line
    during startup. They save little at a ~0.035s startup and can leave
    Emacs looking frozen if something fails.

Measured result: synced startup went from about 0.034s to about 0.037s. The
extra cost is gcmh's autoloads plus keeping the gzip handler, which is a
correctness fix. The splash-screen savings land after the point this number
measures. Phase 5 buys features and correctness, not raw speed.

### Phase 6: Java/JVM parity, an IntelliJ replacement (planned)

**Goal:** a Java developer can do a full working day in Hellmacs without
opening IntelliJ. That means importing and indexing a Maven/Gradle project,
smart completion with auto-import, navigation (including into JDK and
library classes), refactoring, building, testing, debugging, and Git.

The phase covers only that parity set. Everything else is deferred
(see "Not in this phase" below).

**Stack.** Only established packages and built-in Emacs features, each doing
the job it's known for:

| Concern | Package | Why this one |
|---|---|---|
| Language server | `lsp-mode` + `lsp-java` (Eclipse JDTLS) | `lsp-java` covers JDTLS's Java-specific extensions: project import and sync, the class-file decompiler, generate/extract code actions, and the debug and test bundles. eglot speaks plain LSP and leaves those out. |
| Completion UI | `corfu` (already shipped) + `cape` | `lsp-completion-at-point` feeds corfu directly (`lsp-completion-provider :none`), and cape adds file and dabbrev completion around it |
| Diagnostics | Built-in `flymake` (`lsp-diagnostics-provider :flymake`) | Saves a dependency (no flycheck) |
| Debugging and tests | `dap-mode` + `dap-java` | Launch, attach, breakpoints and hot code replace through Microsoft's java-debug, plus running and debugging JUnit tests |
| Build | Built-in `compile` / `project-compile` | ANSI colors via `ansi-color-compilation-filter` (Emacs 28+), and Emacs' existing javac, Maven and Java stack-frame error regexps |
| Projects | Built-in `project.el` | Already used by `C-c h f`. Its `C-x p` map (find file, compile, search, switch) is the vanilla answer to IntelliJ's project view, so no `projectile` and no extra `C-c p` group |
| Git | `magit` | |

**Changes to the existing design** (the audit results):

1. **Default LSP client: lsp-mode, not eglot.** The old Phase 6 made eglot
   the default. For Java, parity needs lsp-java, and lsp-java needs lsp-mode.
   So `:tools lsp` uses lsp-mode by default, and eglot becomes an opt-in
   `+eglot` flag for other languages (the same split as Doom). With
   `+eglot`, `:lang java` warns and uses lsp-mode anyway.
2. **Clojure and Kotlin move to Phase 8.** Parity comes first.
3. **The planned `C-c p` group is dropped.** It would duplicate Emacs'
   built-in `C-x p` map.
4. **The planned `java-ts-mode` default is dropped.** Java uses the built-in
   `java-mode`, which needs no grammar to compile, and `+tree-sitter` opts
   into `java-ts-mode`. The tree-sitter grammar helper moves to Phase 8.
5. **Module names stay conventional; the theme lives in symbols and
   messages.** The modules are `:tools lsp`, `:tools debugger`,
   `:tools build`, `:tools magit` and `:lang java`, so their keys say what
   they do, as in Doom. Public symbols are named `hellmacs-jvm-*` (Java and
   JDTLS) and `hellmacs-forge-*` (building, following `C-c h f`), with
   matching customization groups. "forge" is deliberately not used as a
   module name: `forge` is Magit's GitHub/GitLab package, and a
   `:tools forge` module would be confusing.
6. **Shared dependencies are declared up front.** Phase 3 showed that
   Elpaca can build a dependency twice, and hang, when several packages
   discover it at the same moment (`compat`). lsp-mode, lsp-java, dap-mode
   and lsp-treemacs share dash, f, ht, s, lv, spinner, markdown-mode,
   posframe, bui, treemacs and request, so their packages.el files declare
   those explicitly. Transitive dependencies are listed in the verification
   step.

**New keys** (Emacs conventions; nothing modal):

| Prefix | Owner | Contents |
|---|---|---|
| `C-c l` | `:tools lsp` | lsp-mode's own `lsp-command-map`, via `lsp-keymap-prefix`, so the layout is lsp-mode's documented one: `a a` code action, `r r` rename, `r o` organize imports, `g g`/`g i`/`g r` definition/implementation/references, `= =` format, `w r` restart workspace. which-key names come from `lsp-enable-which-key-integration`. |
| `C-c l j` | `:lang java` | Java only: `b` build project, `u` update project config (after editing pom.xml/build.gradle), `i` add unimplemented methods, `g` generate getters/setters, `s` generate toString, `e` generate equals/hashCode, `m` extract method, `v` extract local variable, `c` extract constant, `h` type hierarchy, `t` / `T` run test at point / test class |
| `C-c d` | `:tools debugger` | `d` start (`dap-debug`), `b` toggle breakpoint, `B` conditional breakpoint, `L` log point, `n` next, `i` step in, `o` step out, `c` continue, `e` eval at point, `r` restart, `q` disconnect, `t` / `T` debug test at point / test class. `n`/`i`/`o`/`c` form a `repeat-map`, so `C-c d n n n` steps three times without a hydra |
| `C-c !` | `:tools lsp` (in `lsp-mode-map` only) | Flymake: `n`/`p` next/previous diagnostic, `l` list. `C-c` + punctuation is the convention for minor-mode keys, as flycheck does |
| Emacs defaults | (built in) | `M-.`/`M-?`/`M-,` definition/references/back (xref); `C-M-.` workspace symbol search; `C-x p c` compile the project; `C-x g` Magit |

`C-c h r` (+crucible/reload) gains a Java meaning: during a debug session,
save and hot-swap the changed classes (java-debug's hot code replace).

**Thematic messages and mode-line.** One function,
`hellmacs-jvm-announce`, prints every status message, so the wording lives
in one table and follows `hellmacs-ux-enable` (plain wording when it's off):

| Event | Themed | Plain |
|---|---|---|
| JDTLS process started | `[FORGE IGNITED] JDTLS bound to <project>` | `JDTLS started for <project>` |
| Import/index finished (JDTLS `ServiceReady`) | `[DAEMON READY] <project> indexed in Ns` | `<project> indexed` |
| Build failed | `[BYTECODE PURGATORY] <first error, file:line>` | `Build failed: ...` |
| Build succeeded | `[FORGE TEMPERED] Built in Ns` | `Build finished` |
| Tests failed | `[TEST DAMNATION] N failed` | `N tests failed` |
| Server crashed or exited | `[DAEMON BANISHED] JDTLS exited; restarting` | `JDTLS exited` |

A mode-line segment, `hellmacs-jvm-mode-line`, goes in the standard
`mode-line-misc-info` (no mode-line package). It shows `JVM:igniting`
(amber), `JVM:ready` (green) or `JVM:purgatory` (red, when the last build
failed), with new theme faces `hellmacs-jvm-busy`, `-ready` and `-failed`.
lsp-mode's own workspace status segment is turned off so the state isn't
shown twice.

#### Steps

Each step ends with its verification. Tests go in the repository from now
on (see 6.0) rather than in throwaway scripts.

**6.0 Foundations** (done)
- [x] `test/` holds the ERT suites (`test-lib.el`, `test-modules.el`,
      `test-core.el`, 19 tests), and `bin/hellmacs test [REGEXP]` runs them
      with every Hellmacs directory pointed at a temporary one.
- [x] `test/fixtures/java/gradle-demo/` and `maven-demo/` have identical
      sources:
  - `App` (`main`), `Greeter`, and a Lombok `@Data` class, `Person`.
  - A passing `GreeterTest`, and a `BrokenTest` that only runs (and fails)
    with `-Dhellmacs.fail=true`.
  - Both target Java 21 and include their wrappers (`gradlew` and `mvnw`).
  - Verified with Gradle 9.7.1 and Maven 3.9.16 on JDK 25: normal runs
    pass, the fail flag fails exactly BrokenTest, and `App` runs.
  - Lombok 1.18.48 works on JDK 25, with only a `sun.misc.Unsafe`
    deprecation warning.
- [x] `package! :env`: environment variables are set before Elpaca builds
      (its build subprocesses inherit them) and again at every startup,
      from the profile. Verified end to end: a local test package recorded
      the variable during compilation, and a synced boot had it set without
      loading Elpaca.
- [x] Module extension points:
  - A module's `cli.el` is loaded by `bin/hellmacs` and `hellmacs-sync`,
    once per session. It can add to `hellmacs-sync-functions` (run at the
    end of every sync) or define `hellmacs-cli-COMMAND` functions.
  - A module's `doctor.el` gets its own section in `bin/hellmacs doctor`
    and uses `hellmacs-doctor-ok/-info/-warn/-error/-executable`.
  - The CLI's hard-coded checks moved out: rg and fd went to
    `:completion vertico`. java, jdtls and clojure-lsp are removed until
    `:lang java` (6.2) and `:lang clojure` (Phase 8) bring them back.
  - Verified with a private test module: a sync step that ran once per
    sync, a new command, and a failing check that made doctor exit 1.
- [x] Theme faces added: lsp-mode (symbol highlights, lenses, inlay hints,
      rename, signature), dap-mode (breakpoints, current-line marker,
      sessions, locals, results), Magit (sections, diffs, branches, blame,
      log, process, signatures, commit messages), and `hellmacs-jvm-busy`,
      `-ready` and `-failed`. The theme now sets 217 faces.
  - Removed diff lines are red on a dark red tint (4.8:1). Highlighted ones
    switch to Ash text (11.6:1), because red on the brighter tint drops
    below 4.5:1.
- [x] **The plan was checked against the installed packages**: lsp-mode,
      lsp-java, dap-mode and Magit, 35 packages in all, installed in 19s with
      no hang. Every option and command name used in the specs below exists.
      Corrections made to the plan:
  - **`dap-java` ships inside lsp-java**, not dap-mode.
  - **`lsp-java-update-server` is deprecated.** The sync pre-install calls
    `lsp-install-server` for `jdtls` instead. That install uses Maven (`mvn`,
    or a Maven wrapper it downloads) to fetch JDTLS (pinned by
    `lsp-java-jdt-download-url`, currently 1.57.0), the java-debug bundle
    **and the JUnit test runner**. So the dap-java test runner is part of
    the normal install, and the build-tool fallback in 6.4 is a backup.
  - **`dap-java-test-runner` defaults under `user-emacs-directory`**, which
    Hellmacs points at the disposable cache. It must be set into the data
    dir before the server is installed.
  - `lsp-java-server-install-dir` is derived from `lsp-server-install-dir`
    when lsp-java loads, so setting the latter first is enough.
  - lsp-java's default `lsp-java-vmargs` equal the spec's apart from
    `-Xmx1G`, which the spec raises to 2G.
  - **Shared dependencies**, computed from Elpaca's dependency data (with
    how many packages use each):
    - lsp side: dash (9), ht (6), f (5), s (5), lsp-mode (4), posframe,
      lv, markdown-mode and treemacs (2 each)
    - Magit side: cond-let and llama (3 each)

    request, bui and lsp-treemacs each have a single user, so they're
    dropped from the up-front lists. Other transitive dependencies are
    installed without declaration: hydra, lsp-docker and yaml (dap-mode);
    ace-window, avy, cfrs and pfuture (treemacs); magit-section and
    with-editor (Magit).

**6.1 `:tools lsp`** (done): `modules/tools/lsp/` (packages.el,
config.el, autoload.el, doctor.el), plus cape in `:completion corfu`.
- [x] lsp-mode, with its shared dependencies declared up front and
      `:env (("LSP_USE_PLISTS" . "true"))`. `+eglot` uses the built-in
      eglot instead, with `C-c l a/r/o/f/i` and the same `C-c !` keys.
- [x] Tuning:
  - `read-process-output-max` 1MB once a server runs, with lsp-mode or
    eglot.
  - gcmh's high threshold 128MB.
  - `lsp-log-io` nil, `lsp-idle-delay` 0.5, `lsp-file-watch-threshold`
    5000.
  - Breadcrumbs and snippets off, and diagnostics through flymake.
- [x] Files: `lsp-session-file` in the state dir, `lsp-server-install-dir`
      in the data dir.
- [x] Completion: `lsp-completion-provider :none`. In LSP buffers the
      completion functions are the server's capf wrapped in
      `cape-capf-buster`, then `cape-file` and `cape-dabbrev`, the same for
      lsp-mode and eglot. Without `:completion corfu`, the server's plain
      capf is used. `:completion corfu` now installs cape and adds
      `cape-file` globally, plus `cape-dabbrev` in text modes.
- [x] Keys: `C-c l` is lsp-mode's own `lsp-command-map`, via
      `lsp-keymap-prefix`, with which-key names; `C-c !` for flymake in
      `lsp-mode-map`. Verified that `C-c l` holds the full command map. Its
      entries stay hidden until a server with the matching capability is
      active, which is lsp-mode's design.
- [x] lsp-mode loads incrementally: it isn't loaded at startup
      (`featurep`), and it is after idle time.
- [x] Startup cost: 0.029s vs 0.027s without the module (+6.5%, within the
      10% criterion). The difference is lsp-mode's and its dependencies'
      autoload files.
- [x] `lsp-doctor` reports all seven checks OK.
- **Found and fixed: an `:env` change didn't rebuild already-installed
  packages.** lsp-mode, installed in 6.0 before it had `:env`, stayed
  compiled with hash tables while `lsp-use-plists` said plists. It misreads
  every server response in that state, and `lsp-doctor` still reports OK
  because it only checks the variable. Two fixes:
  - Sync records the `:env` each package was built with
    (`$XDG_DATA_HOME/hellmacs/build-env/`) and rebuilds any installed
    package whose `:env` changed, including one that dropped its `:env`.
    Verified: the plist accessor returned `nil` before the rebuild and `3`
    after, and a second sync rebuilt nothing. Unit test
    `test-modules/env-change-triggers-rebuild`.
  - `:tools lsp` checks the compiled accessors after lsp-mode loads and
    shows an error telling you to sync if they don't match
    `lsp-use-plists`.
- Not yet verified: completion, navigation and diagnostics against a real
  server. That needs JDTLS, so it's part of 6.2's checks.

**6.2 `:lang java`** (done): `modules/lang/java/` (packages.el,
config.el, autoload.el, doctor.el, cli.el and `+paths.el`).
- [x] lsp-java, started by `lsp-deferred` from `java-mode-hook` (and
      `java-ts-mode-hook`). `+tree-sitter` remaps `java-mode` to
      `java-ts-mode`. lsp-java loads incrementally after startup, or lsp-mode
      loads it through `lsp-client-packages` when the first Java buffer asks
      for a server.
  - The hooks are registered at startup, not behind `:after lsp-mode`, so a
    Java file opened from the command line gets a server too.
- [x] **JDTLS is installed by `bin/hellmacs sync`.** `cli.el` adds a
      `hellmacs-sync-functions` step that calls
      `lsp-install-server nil 'jdtls` and waits for it. That installs JDTLS
      1.57.0, java-debug and the JUnit runner (110MB) into
      `$XDG_DATA_HOME/hellmacs/lsp/`, in 31s here. Later syncs skip it.
  - Paths are set in `+paths.el`, shared by config.el, cli.el and
    doctor.el, before lsp-java loads:
    - `lsp-server-install-dir` → data
    - the JDTLS workspace and index → `data/jvm/workspace/`
    - `dap-java-test-runner` → next to JDTLS, not in the cache
- [x] Settings from the spec: JDK from `hellmacs-jvm-java-home` (JAVA_HOME),
      `-Xmx2G`, the FernFlower decompiler, organize imports on save, Maven
      sources, code lenses and favorite static imports.
- [x] **Status.** `hellmacs-jvm-announce`, driven by the
      `hellmacs-jvm-messages` table, prints themed or plain wording
      depending on `hellmacs-ux-enable`:
  - `[FORGE IGNITED]` from `lsp-after-initialize-hook`
  - `[DAEMON READY] <root> indexed in Ns` when JDTLS sends `ServiceReady`
    (an `:after` advice on `lsp-java--language-status-callback`, which
    otherwise only logs it)
  - `[DAEMON BANISHED]` from `lsp-after-uninitialized-functions`

  Mode-line: `JVM:igniting` / `JVM:ready` via a standard
  `mode-line-misc-info` entry, with states keyed by the normalized project
  root.
- [x] **`C-c l j`** in the Java modes' maps: build, update project config,
      organize imports, add unimplemented methods, generate
      getters/setters, toString and equals/hashCode, extract method, local
      variable and constant, type hierarchy, and run the test at point or
      in the class.
  - lsp-mode's `C-c l` (a minor-mode map) has no `j`, so the key falls
    through to these maps.
  - `u` is `hellmacs-jvm-update-project-configuration`. It works from any
    project file, because lsp-java's own command errors unless run from
    `pom.xml`/`build.gradle`.
- [x] doctor.el checks:
  - the JDK major version (21+ for JDTLS; parses both `1.8` and `25`)
  - JAVA_HOME
  - gradle and mvn
  - whether JDTLS and the JUnit runner are installed
- [x] **Verified against a real JDTLS** on both fixtures, with a probe
      driving a live session. Maven results; Gradle is the same for 1-8:
  1. The project imports: `[FORGE IGNITED]`, then `[DAEMON READY]`, and
     the mode-line shows `JVM:ready`. Import takes about 2.5s when known and
     about 33s the first time (dependency download).
  2. Completing `Lis` offers `java.util.List`, and accepting it **adds
     `import java.util.List;`**.
  3. `M-.` on `String` opens the decompiled `java.lang.String`.
  4. References to `greet` are found in both test classes, **but not in
     `App.java`**. Its call passes `person.getName()`, which comes from
     Lombok and doesn't resolve without the agent (6.3), so JDTLS drops
     the call as an inaccurate match. Rename still finds it. To recheck
     in 6.3.
  5. "Extract to method" is offered for a selected statement (10 code
     actions).
  6. Renaming `greet` → `welcome` updates Greeter, App and GreeterTest.
  7. Organize-on-save removes an unused import.
  8. A type error shows through flymake.
  9. A dependency added to `pom.xml` is on the classpath **within 10s of
     saving**. JDTLS's automatic update works through lsp-mode's file
     watches (14 folders). `C-c l j u` also works, and `StringUtils` then
     completes.
- [x] Unit tests (`test/test-java.el`, 3 tests, 23 in total): themed and
      plain messages, mode-line states (which found and fixed a
      trailing-slash key mismatch), and finding the build file from a
      source file.
- Note: the first time you open a file in a new project, lsp-mode asks
  whether to import its root. That's standard lsp-mode behavior, answered
  once per project and remembered in the state dir.

**6.3 `+lombok`** (done)
- [x] Lombok 1.18.48 is pinned in `+paths.el`, with its SHA-256
      (`85477a46…c508b`). Maven Central only publishes a SHA-1, so the
      SHA-256 comes from a download whose SHA-1 matched Central's. It also
      matches the copy Maven downloaded independently into `~/.m2`.
- [x] `cli.el` adds a sync step with `+lombok`. It downloads the jar to
      `data/jvm/lombok-<version>.jar` via a `.part` file, verifies the
      SHA-256 before moving it into place (so JDTLS never sees a bad jar),
      and re-downloads a corrupt one.
  - Setting `hellmacs-jvm-lombok-jar` in your init.el uses your own jar.
    Sync then only checks that it exists, and fails clearly if it doesn't.
- [x] `config.el` builds `lsp-java-vmargs` from `hellmacs-jvm--vmargs`,
      appending `-javaagent:<jar>` with `+lombok` once the jar exists.
      Startup only checks existence; sync and doctor check the checksum.
      doctor.el reports a missing or corrupt jar as an error.
- [x] **Verified against a live JDTLS on both fixtures:**
  - JDTLS starts with `-javaagent:lombok-1.18.48.jar`.
  - `App.java` has no diagnostics, and `person.getN` completes to
    `getName`.
  - **References to `greet` now find all 3 call sites, including
    `App.java`.** That closes the 6.2 gap.
  - Control run without `+lombok`: "getName() is undefined" and
    "constructor Person(String, int) is undefined", no completion, and 2
    references. So the gap was Lombok, as suspected.
- [x] Sync paths verified: fresh download, skip when installed, a
      corrupted jar flagged by doctor and repaired by sync, and a custom
      path that doesn't exist fails with exit 1.
- [x] Unit tests (25 in total): the javaagent is added only with the flag
      and an existing jar; a download is installed only on a matching
      SHA-256, leaves nothing behind on a mismatch, and isn't repeated.
  - Writing them found that the sync steps reloaded `+paths.el` (and so
    its `defconst`s) on every call. It's now loaded once, when `cli.el`
    loads.

**6.4 `:tools build`** (`modules/tools/build/`: config.el, autoload.el; built-in packages only)
- `compile` settings:
  - ANSI color filter
  - `compilation-scroll-output 'first-error`
  - save buffers without asking
  - `compilation-always-kill`
- Build tool per project, detected by `hellmacs-forge-build-tool`: the
  Gradle wrapper, then Gradle, then the Maven wrapper, then Maven.
  - It sets `compile-command` (`./gradlew build --console=plain` or
    `./mvnw -B compile`), so the built-in `C-x p c` proposes the right
    command.
  - `C-c l j t` (tests) falls back to the build tool
    (`--tests Class.method` / `-Dtest=Class#method`) when dap-java's test
    runner isn't available.
- Error regexps: Emacs already has javac (`gnu`), `maven` and Java stack
  frames (`java`). One is added for Gradle/JUnit 5 failure locations.
- `compilation-finish-functions` show `[FORGE TEMPERED]` or
  `[BYTECODE PURGATORY]` and update the mode-line segment.
- *Verify:*
  1. `C-x p c` on each fixture builds.
  2. A compile error jumps to the file and line with `M-g n`.
  3. The failing test's location is clickable.
  4. Colors render, with no raw escape codes.
  5. Success and failure produce the right message.

**6.5 `:tools debugger`** (`modules/tools/debugger/`: packages.el, config.el, autoload.el)
- dap-mode and dap-java, installed with lsp-java's debug and test bundles.
- `dap-auto-configure-mode` with sessions, locals, breakpoints,
  expressions and REPL. The posframe controls and tooltips are off.
- Breakpoints are saved in the state dir.
- Launch and attach templates: a main class, and remote attach to
  localhost:5005.
- Keys: `C-c d` with its step `repeat-map`, and hot code replace for
  `C-c h r`.
- *Verify:*
  1. A breakpoint in `main` is hit, and the locals show values.
  2. Stepping works with `C-c d n n`.
  3. A conditional breakpoint only stops when its condition holds.
  4. Evaluating an expression shows its value.
  5. Debugging the test at point stops inside the test.
  6. Editing a method body during a session and pressing `C-c h r`
     hot-swaps it.
  7. Attaching to a JVM started with `-agentlib:jdwp=...` works.

**6.6 `:tools magit`** (`modules/tools/magit/`: packages.el, config.el)
- magit with its default global keys (`C-x g`, `C-x M-g`, `C-c M-g`), and
  transient's history and state files in the state dir.
- *Verify:* status, stage/commit, log and blame work on this repository.

**6.7 Integration**
- `static/init.example.el` lists the new modules, commented out, with a
  one-line description each.
- README: Java setup, a key table, and the requirements (a JDK, network
  access on first use).
- `bin/hellmacs doctor` reports every new check.
- *Verify:* a fresh `bin/hellmacs install` with the Java modules on, in
  temporary folders, followed by the 6.2-6.6 checks, passes end to end.

**6.8 Parity acceptance**
- Work through a checklist of IntelliJ features on the fixtures and then
  on one real Maven or Gradle project of yours. Record startup time, time
  until `[DAEMON READY]`, JDTLS memory use, and anything missing. Gaps that
  block daily work get fixed here; everything else goes into Phase 8.

#### Configuration specs

These are the intended blocks. Option and command names follow the current
lsp-mode, lsp-java and dap-mode releases. Each is checked against the
pinned versions in step 6.0, and a renamed option is corrected rather than
worked around.

`modules/tools/lsp/packages.el`
```elisp
;; Shared dependencies first, so Elpaca builds each exactly once.
(package! dash) (package! f) (package! ht) (package! s)
(package! lv) (package! spinner) (package! markdown-mode)
(package! lsp-mode :env (("LSP_USE_PLISTS" . "true")))
```

`modules/tools/lsp/config.el`
```elisp
(defvar hellmacs-lsp-read-process-output-max (* 1024 1024)
  "`read-process-output-max' while a language server runs (lsp-mode's advice).")

(use-package lsp-mode
  :defer-incrementally (lsp-mode lsp-completion lsp-diagnostics lsp-modeline)
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")          ; must be set before lsp-mode loads
  :custom
  (lsp-completion-provider :none)           ; plain capf, rendered by corfu
  (lsp-diagnostics-provider :flymake)
  (lsp-log-io nil)
  (lsp-idle-delay 0.5)
  (lsp-keep-workspace-alive nil)
  (lsp-file-watch-threshold 5000)
  (lsp-headerline-breadcrumb-enable nil)
  (lsp-modeline-workspace-status-enable nil) ; Hellmacs' own segment instead
  (lsp-enable-snippet nil)                   ; no yasnippet in the MVP
  (lsp-session-file (hellmacs-state-file "lsp-session"))
  (lsp-server-install-dir (expand-file-name "lsp/" hellmacs-data-dir))
  :hook
  (lsp-mode . lsp-enable-which-key-integration)
  (lsp-completion-mode . hellmacs-lsp--setup-completion-h)
  (lsp-mode . hellmacs-lsp--tune-process-output-h)
  :bind (:map lsp-mode-map
         ("C-c ! n" . flymake-goto-next-error)
         ("C-c ! p" . flymake-goto-prev-error)
         ("C-c ! l" . flymake-show-buffer-diagnostics)))

(defun hellmacs-lsp--setup-completion-h ()
  "Complete through lsp first, then files and words, all in corfu."
  (setq-local completion-at-point-functions
              (list (cape-capf-buster #'lsp-completion-at-point)
                    #'cape-file #'cape-dabbrev)))

(defun hellmacs-lsp--tune-process-output-h ()
  "Read language-server output in large chunks."
  (setq read-process-output-max hellmacs-lsp-read-process-output-max))

(setq gcmh-high-cons-threshold (* 128 1024 1024))
```

`modules/lang/java/packages.el`
```elisp
;; Shared by several of lsp-java's dependencies (6.0's dependency audit).
(package! posframe) (package! treemacs)
(package! dap-mode)
(package! lsp-java)          ; also provides dap-java
```

`modules/tools/magit/packages.el`
```elisp
(package! cond-let) (package! llama)   ; shared by magit, magit-section, with-editor
(package! magit)
```

`modules/lang/java/config.el`
```elisp
(defvar hellmacs-jvm-java-home (getenv "JAVA_HOME")
  "JDK that runs JDTLS itself (21+). Projects may target other JDKs:
see `lsp-java-configuration-runtimes'.")

(defvar hellmacs-jvm-lombok-jar (expand-file-name "jvm/lombok.jar" hellmacs-data-dir)
  "Lombok jar fetched by `bin/hellmacs sync' with the +lombok flag.")

(use-package lsp-java
  :after lsp-mode
  :hook ((java-mode . lsp-deferred)
         (java-mode . hellmacs-jvm-mode-line-mode))
  :custom
  (lsp-java-workspace-dir (expand-file-name "jvm/workspace/" hellmacs-data-dir))
  (lsp-java-workspace-cache-dir (expand-file-name "jvm/workspace/.cache/" hellmacs-data-dir))
  (lsp-java-java-path (if hellmacs-jvm-java-home
                          (expand-file-name "bin/java" hellmacs-jvm-java-home)
                        "java"))
  (lsp-java-vmargs '("-XX:+UseParallelGC" "-XX:GCTimeRatio=4"
                     "-XX:AdaptiveSizePolicyWeight=90"
                     "-Dsun.zip.disableMemoryMapping=true"
                     "-Xmx2G" "-Xms256m"))
  (lsp-java-content-provider-preferred "fernflower")   ; decompile library classes
  (lsp-java-save-actions-organize-imports t)
  (lsp-java-maven-download-sources t)
  (lsp-java-references-code-lens-enabled t)
  (lsp-java-implementations-code-lens-enabled t)
  (lsp-java-completion-favorite-static-members
   ["org.junit.jupiter.api.Assertions.*" "org.assertj.core.api.Assertions.*"
    "org.mockito.Mockito.*" "org.mockito.ArgumentMatchers.*"])
  :config
  (when (modulep! +lombok)
    (if (file-exists-p hellmacs-jvm-lombok-jar)
        (add-to-list 'lsp-java-vmargs (concat "-javaagent:" hellmacs-jvm-lombok-jar) t)
      (display-warning 'hellmacs "+lombok: no Lombok jar yet; run `bin/hellmacs sync'")))
  (add-hook 'lsp-after-initialize-hook #'hellmacs-jvm--announce-ignition-h))

;; dap-java (shipped with lsp-java) must find its test runner in the data
;; dir, not the disposable cache; `lsp-install-server' puts it there.
(setq dap-java-test-runner
      (expand-file-name "lsp/eclipse.jdt.ls/test-runner/junit-platform-console-standalone.jar"
                        hellmacs-data-dir))

;; Build commands come from :tools build; only wire them up when it's on.
(when (modulep! :tools build)
  (add-hook 'java-mode-hook #'hellmacs-forge-setup-build-h))
```

`modules/tools/debugger/config.el`
```elisp
(use-package dap-mode
  :after lsp-mode
  :commands (dap-debug dap-breakpoint-toggle)
  :custom
  (dap-auto-configure-features '(sessions locals breakpoints expressions repl))
  (dap-breakpoints-file (hellmacs-state-file "dap-breakpoints"))
  :config
  (dap-auto-configure-mode 1)
  (require 'dap-java))

(defvar-keymap hellmacs-debug-repeat-map
  :repeat t
  "n" #'dap-next  "i" #'dap-step-in  "o" #'dap-step-out  "c" #'dap-continue)
```

`modules/tools/build/config.el`
```elisp
(use-package compile
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter)
  :custom
  (compilation-scroll-output 'first-error)
  (compilation-always-kill t)
  (compilation-ask-about-save nil)          ; save modified buffers, don't ask
  (compilation-max-output-line-length nil)
  :config
  (add-hook 'compilation-finish-functions #'hellmacs-forge--report-h))
```

#### Not in this phase

Each item below has an established package, but none is needed to replace
IntelliJ for daily Java work:

- lsp-ui (sideline and peek views)
- the treemacs project tree UI (treemacs is installed only as a
  dependency)
- Spring Boot tooling
- yasnippet argument placeholders
- test coverage
- profiling
- database tools
- Docker
- Kotlin and Clojure (Phase 8)

#### Risks

- **JDTLS needs a recent JDK** (21+) and 1-2GB of memory. doctor checks
  the JDK. `-Xmx` in `lsp-java-vmargs` is the knob to turn.
- **JDTLS, the java-debug bundle and Lombok download from the network on
  first use.** Pre-installing them from `bin/hellmacs sync` keeps those
  downloads out of editing sessions.
- **The dependency tree is deep.** lsp-java and dap-mode pull in lsp-mode,
  treemacs and about ten libraries. Declaring them up front (see change 6)
  and locking them with `bin/hellmacs lock` keep builds reproducible.
- **dap-java's test runner** comes with lsp-java's test bundle. If it's
  unavailable, tests run through the build tool (6.4).

### Phase 7: Visual identity and thematic UX (done)

This phase came in as its own spec and is independent of Phase 6, so it
landed first. All of it respects the keybinding policy: Emacs keys, no
evil, nothing modal.

- [x] **`themes/hellmacs-theme.el`**: a zero-dependency `deftheme` in the
      Hellmacs palette.
  - Colors: Obsidian Void background, Charcoal Iron mode-line and current
    line, Brimstone Red cursor, warnings and current line number, Argent
    Amber keywords, functions and active mode-line text, Toxic Green
    strings and REPL results, Ash White text, and Grave Slate comments and
    inactive line numbers.
  - Covers the built-in faces, font-lock (including the Emacs 29+
    tree-sitter faces), completions, vertico, orderless, marginalia,
    consult, corfu, which-key, line numbers, both mode-lines, compilation,
    flymake/eglot, comint and CIDER, plus Hellmacs' own faces.
  - Background tints (selection, popup highlight, ...) are derived from the
    palette and used only as backgrounds.
  - `:ui theme` loads it through `hellmacs-theme` (default `hellmacs`; set
    another theme or nil in your init.el) and turns on `hl-line-mode` in
    prog and text buffers.
- [x] **`core/hellmacs-splash.el`**: the Altar.
  - A read-only `*hellmacs*` buffer (`hellmacs-splash-mode`, derived from
    `special-mode`) is shown through `initial-buffer-choice`, including in
    `emacsclient -c` frames.
  - Content: the horned cyber-cat sigil, the tagline, and
    `[ALTAR] Bound in X.XXX seconds with N garbage collections.`
  - Buttons for scratch, find file, recent files and project; TAB/RET move
    and follow, `g` redraws, `q` buries.
  - It re-centers on window resize, and redraws once the startup time is
    known.
  - When Emacs is started with a file or directory, that buffer is shown
    instead of splitting the frame.
  - `hellmacs-splash-enable` turns it off. The GNU splash was already off
    (early-init).
- [x] **`hellmacs-prefix-map` on `C-c h`**, with the spec's keys and
      which-key names:
  - `s` +altar/return (the splash)
  - `f` +forge/find-file (`project-find-file`; outside a project, pick one
    first)
  - `c` +altar/reap (`garbage-collect`, reporting the memory still in use)
  - `r` +crucible/reload (`cider-load-buffer` in a Clojure buffer,
    `cider-ns-refresh` elsewhere; a clear message when no REPL is
    connected)
- [x] **`core/hellmacs-ux.el`**:
  - `confirm-kill-emacs` asks "Extinguish the forge and return to the
    void?"
  - `command-error-function` reports unhandled errors as
    `[CRITICAL FATALITY]: <message>` in Brimstone Red. `user-error`s and
    `C-g` keep the plain reporting, because they aren't failures.
  - JVM exceptions, Clojure errors and Gradle/Maven build failures are
    colored red in compilation, comint and CIDER REPL buffers, and stack
    frames are dimmed.
  - Interactive only. `hellmacs-ux-enable` turns it off.

Where this departs from the spec, and why:
- **The bindings live in the `:config default` module**, not in
  `modules/hellmacs-bindings.el`. Flat module files were retired in
  Phase 2, and the keybinding policy gives each leader group exactly one
  owner, which for `C-c h` is `:config default`.
- **`C-c h r` and `C-c h s` used to mean "reload config" and "sync
  packages".** The spec's meanings win, and those two moved to `C-c h R`
  and `C-c h S`.
- **"1 garbage collection" is singular.** The rest of the altar line
  follows the spec exactly.
- **Grave Slate is 2.9:1 against the background**, below WCAG AA (4.5:1).
  It's kept as specified, for recessive comments and line numbers. Every
  other text color is 5.2:1 or better (Ash 13.6, Green 14.6, Amber 8.3,
  Red 5.2).

### Phase 8: More JVM languages (planned)

This is the old Phase 6's Clojure and Kotlin work, moved after Java parity.
It reuses `:tools lsp`, `:tools debugger` and `:tools build`.

- [ ] **`:lang clojure`**:
  - `clojure-mode`, or `clojure-ts-mode` with `+tree-sitter`.
  - **CIDER** for the REPL, with its standard `C-c C-...` keys, loaded
    incrementally.
  - clojure-lsp through lsp-mode.
  - `C-c h r` (+crucible/reload) already uses CIDER (Phase 7).
- [ ] **`:lang kotlin`**: `kotlin-ts-mode` plus kotlin-language-server
      through lsp-mode, and a Gradle Kotlin error regexp in `:tools build`.
- [ ] **Tree-sitter grammars**: `hellmacs-treesit-ensure` installs pinned
      grammars from `bin/hellmacs sync` for `+tree-sitter` modes.
- [ ] Items deferred from Phase 6 that users ask for: lsp-ui, Spring Boot
      tooling, coverage.

### Out of scope

- straight.el
- Doom's `compat` module and v2 deprecation shims
- The docs system (`doom-docs.el`)
- Windows-specific hacks
- The full `defcli!` framework
- The `:doom` and `:user` virtual modules. Depth numbers are enough.

## Risks

- **Phase 3 was the hard part.** Elpaca is asynchronous, so the profile can
  only be written after `elpaca-wait` returns and every build step has
  finished. Autoload order must follow Elpaca's dependency graph. Shared
  dependencies must be declared up front (see the `compat` fix above).
- **The XDG move reinstalls every package once.**
