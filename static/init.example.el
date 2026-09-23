;;; init.el --- Your Hellmacs init file -*- lexical-binding: t; -*-

;; Loaded after Hellmacs' core, but BEFORE any module. Use it to choose
;; which modules load (the `hellmacs!' block) and to set variables that
;; modules read while loading. Everything else belongs in config.el.
;;
;; This file lives in `hellmacs-user-dir' (~/.config/hellmacs/ by
;; default, or $HELLMACSDIR), outside the Hellmacs git checkout, so
;; upgrading Hellmacs never touches it. Without it, Hellmacs uses the
;; `hellmacs!' block below (it reads this very file from static/).
;;
;; After changing this block, run `bin/hellmacs sync' (or `C-c h s').
;;
;; Modules load in the order listed. Comment a line out to disable a
;; module; +flags turn on optional behavior, documented at the top of
;; each module's config.el (modules/<group>/<name>/config.el).
;;
;; The list below is every module Hellmacs has or could have. Enabled by
;; default: what a JVM project needs. Entries marked [planned] are on the
;; roadmap (docs/roadmap.md) and [idea] ones aren't yet; neither exists,
;; so enabling one only warns "Unknown module ..., skipped" until it
;; lands. To write one yourself, start from static/module-template/.

(hellmacs! :ui
           theme              ; the Hellmacs theme, line numbers, current line
           ;;dashboard        ; [planned] startup dashboard with the sigil, C-c h s
           ;;modeline         ; [planned] minimal doom-modeline in the Hellmacs palette
           ;;hl-todo          ; [idea] highlight TODO/FIXME/HACK comments
           ;;indent-guides    ; [idea] indentation guides
           ;;ligatures        ; [idea] font ligatures in graphical frames
           ;;treemacs         ; [idea] a project file tree
           ;;vc-gutter        ; [idea] changed lines in the fringe (diff-hl)
           ;;workspaces       ; [idea] tab-bar workspaces, one per project

           :editor
           undo               ; persistent undo history (undo-fu-session)
           ;;format           ; [idea] format on save (apheleia)
           ;;multiple-cursors ; [idea] multiple cursors, on stock keys
           ;;snippets         ; [idea] code snippets (yasnippet, tempel)
           ;;fold             ; [idea] code folding (hideshow, treesit-fold)

           :completion
           vertico            ; minibuffer completion + consult commands
           corfu              ; in-buffer completion popup (+tab: TAB completes)

           :emacs
           ;;dired            ; [idea] dired tweaks (dired-x, wdired)
           ;;ibuffer          ; [idea] ibuffer grouped by project
           ;;vc               ; [idea] built-in version control tweaks

           :term
           ;;eshell           ; [idea] eshell with project-aware prompts
           ;;vterm            ; [idea] a real terminal (needs a C toolchain)

           :checkers
           ;;spell            ; [idea] spell checking (jinx)

           :tools
           build              ; build/test with Gradle or Maven (C-x p c), clickable errors
           debugger           ; debug via dap-mode, C-c d (Java: breakpoints, tests, hot swap)
           lsp                ; code intelligence via lsp-mode, C-c l (+eglot: eglot instead)
           magit              ; Git via Magit: C-x g status, C-x M-g dispatch, C-c M-g file
           ;;direnv           ; [idea] per-project environments (envrc)
           ;;docker           ; [idea] Docker containers, images and Dockerfiles
           ;;editorconfig     ; [idea] honour .editorconfig files
           ;;make             ; [idea] run Makefile targets
           ;;rest             ; [idea] HTTP requests from a buffer (verb, restclient)
           ;;terraform        ; [idea] Terraform and HCL

           :lang
           (java +lombok)     ; Java via JDTLS: a JDK 21+ (+lombok, +tree-sitter)
           kotlin             ; Kotlin via kotlin-language-server: a JDK (+tree-sitter)
           clojure            ; Clojure: CIDER REPL + clojure-lsp (+tree-sitter: Emacs 30.1+)
           ;;groovy           ; [planned] Groovy, Gradle scripts, Jenkinsfiles via groovy-language-server
           ;;scala            ; [planned] Scala via Metals, sbt (+tree-sitter)
           ;;cc               ; [idea] C and C++ (clangd)
           ;;data             ; [idea] CSV and XML
           ;;docker           ; [idea] Dockerfile and Compose files
           ;;emacs-lisp       ; [idea] Emacs Lisp extras (eldoc, macrostep)
           ;;go               ; [idea] Go (gopls)
           ;;javascript       ; [idea] JavaScript and TypeScript (typescript-language-server)
           ;;json             ; [idea] JSON
           ;;markdown         ; [idea] Markdown
           ;;org              ; [idea] Org mode
           ;;python           ; [idea] Python (basedpyright, ruff)
           ;;rust             ; [idea] Rust (rust-analyzer)
           ;;sh               ; [idea] shell scripts (bash-language-server, shellcheck)
           ;;sql              ; [idea] SQL
           ;;web              ; [idea] HTML and CSS
           ;;yaml             ; [idea] YAML (yaml-language-server)
           ;;zig              ; [idea] Zig (zls)

           :config
           default)           ; C-c leader groups: h, q, w; which-key

;; Look and feel (all optional):
;; (setq hellmacs-theme 'modus-vivendi)   ; another theme; nil loads none
;; (setq hellmacs-splash-enable nil)      ; start on *scratch*, not the Altar
;; (setq hellmacs-ux-enable nil)          ; stock quit prompt and error messages

;;; init.el ends here
