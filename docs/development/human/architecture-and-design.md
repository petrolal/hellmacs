# Architecture & Design System

This document outlines the software architecture, lifecycle management, and design philosophy of **Hellmacs** for developers and designers.

---

## 1. High-Level Architecture

Hellmacs is structured into four distinct layers:

```
+-------------------------------------------------------------------------+
|                              USER CONFIG                                |
|          ~/.config/hellmacs/ (init.el, packages.el, config.el)          |
+-------------------------------------------------------------------------+
                                    │
                                    ▼
+-------------------------------------------------------------------------+
|                             MODULE SYSTEM                               |
|        modules/<group>/<name>/ (ui, editor, completion, tools, lang)    |
+-------------------------------------------------------------------------+
                                    │
                                    ▼
+-------------------------------------------------------------------------+
|                             CORE ENGINE                                 |
|     early-init.el, core/hellmacs-core.el, core/hellmacs-sync.el         |
+-------------------------------------------------------------------------+
                                    │
                                    ▼
+-------------------------------------------------------------------------+
|                         BASE RUNTIME & CLI                              |
|           Emacs 29+ (Native Comp) + bin/hellmacs CLI Tool               |
+-------------------------------------------------------------------------+
```

---

## 2. Boot Lifecycle & Speed Optimization

Hellmacs achieves **~0.05s startup time** through a two-phase initialization model:

```
[ Pre-Frame (early-init.el) ]
  ├── Disable GUI chrome (tool-bar, menu-bar, scroll-bar)
  ├── Set aggressive GC threshold (1GB during boot)
  ├── Isolate XDG directories (~/.config, ~/.local/share, ~/.cache, ~/.local/state)
  └── Enforce native compilation caches

[ Orchestrator (init.el) ]
  ├── Load core/ library and macros
  ├── Check Synced Profile (~/.local/share/hellmacs/profiles/default/profile.eld)
  │     ├── IF Up-to-Date: Load compiled autoloads & activate packages instantly
  │     └── IF Out-of-Date / Missing: Fall back to Elpaca live bootstrap
  ├── Load active module init.el files
  ├── Load active module config.el files
  └── Load user's personal ~/.config/hellmacs/config.el
```

---

## 3. The Design System: *Inferno* Aesthetic

Hellmacs uses a thematic design language inspired by dark metal, brimstone, and industrial computing:

### Palette Specification (`hellmacs-inferno-theme.el`)
* **Background (Charcoal)**: `#16171d` / `#1b1c24`
* **Foreground (Bone White)**: `#bbc2cf`
* **Accent Primary (Inferno Crimson)**: `#ff6c6b`
* **Accent Secondary (Ember Amber)**: `#da8548`
* **Accent Tertiary (Reap Gold)**: `#ecbe7b`
* **Success / Ready (Venom Green)**: `#98be65`
* **Selection / Highlight**: `#22242f`

### Themed UX Terminology
* **The Altar (`*hellmacs*`)**: The startup dashboard featuring the cyber-cat sigil and startup benchmarks.
* **The Forge**: Project indexing and file discovery (`C-c h f`).
* **The Crucible**: Hot-code bytecode replacement and REPL injection (`C-c h r`).
* **The Reaper**: Instant GC memory collection (`C-c h c`).
* **Daemon States**:
  * `[FORGE IGNITED]`: Language server process spawned.
  * `[DAEMON READY]`: Indexing finished; workspace operational.
  * `[BYTECODE PURGATORY]`: Build or project import failure.
  * `[DAEMON BANISHED]`: Language server process exited.
  * `[TEST DAMNATION]`: Unit test assertions failed.

### Corporate Neutrality Toggle
For strict enterprise environments where a neutral interface is preferred, the theme and terminology can be adjusted in `~/.config/hellmacs/init.el`:

```elisp
;; Disable themed echo area messages and custom quit dialog
(setq hellmacs-ux-enable nil)

;; Start on blank *scratch* buffer instead of The Altar
(setq hellmacs-splash-enable nil)

;; Use standard Modus or custom theme
(setq hellmacs-theme 'modus-vivendi)
```
