;;; hellmacs-theme.el --- Hellmacs' infernal high-contrast dark theme -*- lexical-binding: t; -*-

;; Copyright (C) 2026 petrolal <petrolalucas@gmail.com>
;;
;; Author: petrolal <petrolalucas@gmail.com>
;; URL: https://github.com/petrolal/hellmacs
;; License: GPL-3.0-or-later
;;
;; This file is part of Hellmacs.
;;
;; Hellmacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Hellmacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; A self-contained `deftheme' (no dependencies) built from seven colors:
;;
;;   Obsidian Void  #0a0a0c  buffer background
;;   Charcoal Iron  #16161a  mode-line, current line, popups
;;   Brimstone Red  #ff1a40  cursor, errors/warnings, current line number
;;   Argent Amber   #ff8800  keywords, functions, active mode-line text
;;   Toxic Green    #00ff66  strings, success, REPL results
;;   Ash White      #d6d6d8  default text
;;   Grave Slate    #5a5a66  comments, inactive line numbers
;;
;; Against the background, text contrast is 13.6:1 (Ash), 14.6:1
;; (Green), 8.3:1 (Amber) and 5.2:1 (Red). Grave Slate is 2.9:1:
;; deliberately recessive for comments and line numbers, below WCAG AA
;; (4.5:1).
;;
;; The few extra shades below (selection, popup highlight, ...) are
;; tints of the palette, used only as backgrounds.
;;
;; Covers the built-in faces, font-lock, the minibuffer and completion
;; stack Hellmacs ships (vertico, orderless, marginalia, consult, corfu,
;; which-key), line numbers, mode-lines, compilation, flymake/eglot,
;; comint REPLs, the JVM tooling (lsp-mode, dap-mode, Magit) and the
;; Hellmacs splash screen.
;;
;; Load it with (load-theme 'hellmacs t); the `:ui theme' module does.

;;; Code:

(deftheme hellmacs
  "Infernal high-contrast dark theme: obsidian, brimstone, amber and toxic green.")

(let ((void    "#0a0a0c")
      (iron    "#16161a")
      (red     "#ff1a40")
      (amber   "#ff8800")
      (green   "#00ff66")
      (ash     "#d6d6d8")
      (slate   "#5a5a66")
      ;; Background-only tints.
      (abyss   "#0f0f12")               ; inactive mode-line, fringes of popups
      (ember   "#3d0a14")               ; selection
      (smolder "#2a0a12")               ; highlighted popup candidate
      (soot    "#2a2a33")               ; matching paren, secondary selection
      (rust    "#3a2600")               ; lazy search matches
      (moss    "#0d2416")               ; added lines (diffs)
      (moss-hl "#123a20"))              ; added lines, highlighted hunk
  (custom-theme-set-faces
   'hellmacs

   ;;; Basics
   `(default ((t (:background ,void :foreground ,ash))))
   `(cursor ((t (:background ,red))))
   `(fringe ((t (:background ,void :foreground ,slate))))
   `(region ((t (:background ,ember :extend t))))
   `(secondary-selection ((t (:background ,soot :extend t))))
   `(highlight ((t (:background ,iron :foreground ,amber))))
   `(hl-line ((t (:background ,iron :extend t))))
   `(shadow ((t (:foreground ,slate))))
   `(vertical-border ((t (:foreground ,iron))))
   `(window-divider ((t (:foreground ,iron))))
   `(window-divider-first-pixel ((t (:foreground ,iron))))
   `(window-divider-last-pixel ((t (:foreground ,iron))))
   `(minibuffer-prompt ((t (:foreground ,amber :weight bold))))
   `(link ((t (:foreground ,amber :underline t))))
   `(link-visited ((t (:foreground ,red :underline t))))
   `(button ((t (:inherit link))))
   `(escape-glyph ((t (:foreground ,red))))
   `(homoglyph ((t (:foreground ,red))))
   `(trailing-whitespace ((t (:background ,red))))
   `(tooltip ((t (:background ,iron :foreground ,ash))))
   `(header-line ((t (:background ,iron :foreground ,ash))))
   `(error ((t (:foreground ,red :weight bold))))
   `(warning ((t (:foreground ,red))))
   `(success ((t (:foreground ,green :weight bold))))
   `(match ((t (:foreground ,void :background ,amber))))
   `(isearch ((t (:foreground ,void :background ,amber :weight bold))))
   `(isearch-fail ((t (:foreground ,void :background ,red))))
   `(lazy-highlight ((t (:foreground ,amber :background ,rust))))
   `(show-paren-match ((t (:foreground ,amber :background ,soot :weight bold))))
   `(show-paren-mismatch ((t (:foreground ,void :background ,red :weight bold))))

   ;;; Line numbers
   `(line-number ((t (:foreground ,slate :background ,void))))
   `(line-number-current-line ((t (:foreground ,red :background ,iron :weight bold))))
   `(line-number-major-tick ((t (:inherit line-number :weight bold))))
   `(line-number-minor-tick ((t (:inherit line-number))))

   ;;; Mode-line
   `(mode-line ((t (:background ,iron :foreground ,amber :box (:line-width 1 :color ,iron)))))
   `(mode-line-active ((t (:inherit mode-line))))
   `(mode-line-inactive ((t (:background ,abyss :foreground ,slate :box (:line-width 1 :color ,abyss)))))
   `(mode-line-buffer-id ((t (:foreground ,amber :weight bold))))
   `(mode-line-emphasis ((t (:foreground ,red :weight bold))))
   `(mode-line-highlight ((t (:box (:line-width 1 :color ,amber)))))

   ;;; Font-lock
   `(font-lock-keyword-face ((t (:foreground ,amber :weight bold))))
   `(font-lock-builtin-face ((t (:foreground ,amber))))
   `(font-lock-function-name-face ((t (:foreground ,amber))))
   `(font-lock-function-call-face ((t (:foreground ,amber))))
   `(font-lock-string-face ((t (:foreground ,green))))
   `(font-lock-doc-face ((t (:foreground ,green :slant italic))))
   `(font-lock-doc-markup-face ((t (:foreground ,amber :slant italic))))
   `(font-lock-comment-face ((t (:foreground ,slate :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
   `(font-lock-type-face ((t (:foreground ,ash :weight bold))))
   `(font-lock-constant-face ((t (:foreground ,green :weight bold))))
   `(font-lock-number-face ((t (:foreground ,green))))
   `(font-lock-variable-name-face ((t (:foreground ,ash))))
   `(font-lock-variable-use-face ((t (:foreground ,ash))))
   `(font-lock-property-name-face ((t (:foreground ,ash))))
   `(font-lock-property-use-face ((t (:foreground ,ash))))
   `(font-lock-preprocessor-face ((t (:foreground ,amber :slant italic))))
   `(font-lock-warning-face ((t (:foreground ,red :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,red))))
   `(font-lock-escape-face ((t (:foreground ,red))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,red))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,amber))))
   `(font-lock-operator-face ((t (:foreground ,ash))))
   `(font-lock-bracket-face ((t (:foreground ,ash))))
   `(font-lock-delimiter-face ((t (:foreground ,ash))))
   `(font-lock-punctuation-face ((t (:foreground ,ash))))
   `(font-lock-misc-punctuation-face ((t (:foreground ,ash))))

   ;;; Built-in completion
   `(completions-common-part ((t (:foreground ,amber :weight bold))))
   `(completions-first-difference ((t (:foreground ,red :weight bold))))
   `(completions-annotations ((t (:foreground ,slate :slant italic))))
   `(completions-highlight ((t (:background ,iron :foreground ,amber))))

   ;;; Vertico / orderless / marginalia / consult
   `(vertico-current ((t (:background ,iron :foreground ,amber :weight bold :extend t))))
   `(vertico-group-title ((t (:foreground ,slate :slant italic))))
   `(vertico-group-separator ((t (:foreground ,slate :strike-through t))))
   `(vertico-multiline ((t (:foreground ,slate))))
   `(orderless-match-face-0 ((t (:foreground ,amber :weight bold))))
   `(orderless-match-face-1 ((t (:foreground ,green :weight bold))))
   `(orderless-match-face-2 ((t (:foreground ,red :weight bold))))
   `(orderless-match-face-3 ((t (:foreground ,ash :weight bold :underline t))))
   `(marginalia-documentation ((t (:foreground ,slate :slant italic))))
   `(marginalia-key ((t (:foreground ,amber))))
   `(marginalia-file-priv-dir ((t (:foreground ,amber))))
   `(consult-preview-line ((t (:background ,iron :extend t))))
   `(consult-preview-match ((t (:inherit isearch))))
   `(consult-file ((t (:foreground ,ash))))
   `(consult-bookmark ((t (:foreground ,amber))))

   ;;; Corfu
   `(corfu-default ((t (:background ,iron :foreground ,ash))))
   `(corfu-current ((t (:background ,smolder :foreground ,amber :weight bold))))
   `(corfu-bar ((t (:background ,red))))
   `(corfu-border ((t (:background ,slate))))
   `(corfu-annotations ((t (:foreground ,slate :slant italic))))
   `(corfu-deprecated ((t (:foreground ,slate :strike-through t))))
   `(corfu-popupinfo ((t (:inherit corfu-default))))

   ;;; which-key
   `(which-key-key-face ((t (:foreground ,amber :weight bold))))
   `(which-key-separator-face ((t (:foreground ,slate))))
   `(which-key-command-description-face ((t (:foreground ,ash))))
   `(which-key-group-description-face ((t (:foreground ,red))))
   `(which-key-local-map-description-face ((t (:foreground ,green))))
   `(which-key-note-face ((t (:foreground ,slate))))

   ;;; Compilation, diagnostics, REPLs
   `(compilation-error ((t (:foreground ,red :weight bold))))
   `(compilation-warning ((t (:foreground ,amber :weight bold))))
   `(compilation-info ((t (:foreground ,green))))
   `(compilation-line-number ((t (:foreground ,slate))))
   `(compilation-column-number ((t (:foreground ,slate))))
   `(compilation-mode-line-exit ((t (:foreground ,green :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,red :weight bold))))
   `(flymake-error ((t (:underline (:style wave :color ,red)))))
   `(flymake-warning ((t (:underline (:style wave :color ,amber)))))
   `(flymake-note ((t (:underline (:style wave :color ,green)))))
   `(eglot-highlight-symbol-face ((t (:background ,soot :weight bold))))
   `(eglot-mode-line ((t (:foreground ,green :weight bold))))
   `(comint-highlight-prompt ((t (:foreground ,amber :weight bold))))
   `(comint-highlight-input ((t (:foreground ,ash :weight bold))))
   `(cider-result-overlay-face ((t (:foreground ,green :background ,iron))))
   `(cider-repl-result-face ((t (:foreground ,green))))
   `(cider-error-highlight-face ((t (:underline (:style wave :color ,red)))))

   ;;; lsp-mode
   `(lsp-face-highlight-textual ((t (:background ,soot))))
   `(lsp-face-highlight-read ((t (:background ,soot :underline (:color ,green)))))
   `(lsp-face-highlight-write ((t (:background ,soot :underline (:color ,red) :weight bold))))
   `(lsp-face-rename ((t (:background ,ember :foreground ,ash))))
   `(lsp-rename-placeholder-face ((t (:foreground ,amber))))
   `(lsp-lens-face ((t (:foreground ,slate :height 0.9))))
   `(lsp-lens-mouse-face ((t (:foreground ,amber :underline t :height 0.9))))
   `(lsp-inlay-hint-face ((t (:foreground ,slate :slant italic))))
   `(lsp-signature-highlight-function-argument ((t (:foreground ,amber :weight bold))))
   `(lsp-details-face ((t (:foreground ,slate :height 0.9))))
   `(lsp-modeline-code-actions-face ((t (:foreground ,amber))))
   `(lsp-modeline-code-actions-preferred-face ((t (:foreground ,green :weight bold))))
   `(lsp-installation-buffer-face ((t (:foreground ,amber))))
   `(lsp-installation-finished-buffer-face ((t (:foreground ,green))))

   ;;; dap-mode
   `(dap-ui-pending-breakpoint-face ((t (:underline (:color ,slate)))))
   `(dap-ui-verified-breakpoint-face ((t (:background ,ember :extend t))))
   `(dap-ui-breakpoint-verified-fringe ((t (:foreground ,red :weight bold))))
   `(dap-ui-marker-face ((t (:background ,smolder :extend t))))
   `(dap-ui-compile-errline ((t (:foreground ,red :weight bold))))
   `(dap-result-overlay-face ((t (:foreground ,green :background ,iron))))
   `(dap-ui-sessions-active-session-face ((t (:foreground ,amber :weight bold))))
   `(dap-ui-sessions-running-face ((t (:foreground ,green))))
   `(dap-ui-sessions-terminated-face ((t (:foreground ,slate))))
   `(dap-ui-sessions-terminated-active-face ((t (:foreground ,slate :weight bold))))
   `(dap-ui-sessions-thread-face ((t (:foreground ,ash))))
   `(dap-ui-sessions-thread-active-face ((t (:foreground ,amber))))
   `(dap-ui-sessions-stack-frame-face ((t (:foreground ,ash))))
   `(dap-ui-locals-scope-face ((t (:foreground ,amber :weight bold))))
   `(dap-ui-locals-variable-face ((t (:foreground ,ash :weight bold))))
   `(dap-ui-locals-variable-leaf-face ((t (:foreground ,ash))))

   ;;; Magit
   `(magit-section-heading ((t (:foreground ,amber :weight bold))))
   `(magit-section-secondary-heading ((t (:foreground ,amber))))
   `(magit-section-highlight ((t (:background ,iron :extend t))))
   `(magit-section-heading-selection ((t (:foreground ,red :weight bold))))
   `(magit-section-child-count ((t (:foreground ,slate))))
   `(magit-header-line ((t (:foreground ,amber :weight bold))))
   `(magit-dimmed ((t (:foreground ,slate))))
   `(magit-hash ((t (:foreground ,slate))))
   `(magit-tag ((t (:foreground ,amber))))
   `(magit-filename ((t (:foreground ,ash))))
   `(magit-branch-local ((t (:foreground ,amber))))
   `(magit-branch-remote ((t (:foreground ,green))))
   `(magit-branch-remote-head ((t (:foreground ,green :box (:line-width 1 :color ,green)))))
   `(magit-branch-current ((t (:foreground ,amber :box (:line-width 1 :color ,amber)))))
   `(magit-branch-upstream ((t (:slant italic))))
   `(magit-branch-warning ((t (:foreground ,red))))
   `(magit-head ((t (:foreground ,amber :weight bold))))
   `(magit-keyword ((t (:foreground ,green))))
   `(magit-log-author ((t (:foreground ,amber))))
   `(magit-log-date ((t (:foreground ,slate))))
   `(magit-log-graph ((t (:foreground ,slate))))
   `(magit-diff-file-heading ((t (:foreground ,ash :weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,iron :weight bold))))
   `(magit-diff-file-heading-selection ((t (:background ,iron :foreground ,amber))))
   `(magit-diff-hunk-heading ((t (:background ,iron :foreground ,slate :extend t))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,soot :foreground ,ash :extend t))))
   `(magit-diff-hunk-heading-selection ((t (:background ,soot :foreground ,amber :extend t))))
   `(magit-diff-hunk-region ((t (:inherit bold))))
   `(magit-diff-context ((t (:foreground ,slate :extend t))))
   `(magit-diff-context-highlight ((t (:background ,iron :foreground ,ash :extend t))))
   `(magit-diff-added ((t (:background ,moss :foreground ,green :extend t))))
   `(magit-diff-added-highlight ((t (:background ,moss-hl :foreground ,green :extend t))))
   `(magit-diff-removed ((t (:background ,smolder :foreground ,red :extend t))))
   `(magit-diff-removed-highlight ((t (:background ,ember :foreground ,ash :extend t))))
   `(magit-diff-lines-heading ((t (:background ,amber :foreground ,void))))
   `(magit-diff-whitespace-warning ((t (:background ,red))))
   `(magit-diffstat-added ((t (:foreground ,green))))
   `(magit-diffstat-removed ((t (:foreground ,red))))
   `(magit-blame-heading ((t (:background ,iron :foreground ,slate :extend t))))
   `(magit-blame-highlight ((t (:background ,iron :foreground ,ash :extend t))))
   `(magit-blame-hash ((t (:foreground ,slate))))
   `(magit-blame-name ((t (:foreground ,amber))))
   `(magit-blame-date ((t (:foreground ,slate))))
   `(magit-blame-summary ((t (:foreground ,ash))))
   `(magit-process-ok ((t (:foreground ,green :weight bold))))
   `(magit-process-ng ((t (:foreground ,red :weight bold))))
   `(magit-mode-line-process ((t (:foreground ,amber))))
   `(magit-mode-line-process-error ((t (:foreground ,red :weight bold))))
   `(magit-signature-good ((t (:foreground ,green))))
   `(magit-signature-bad ((t (:foreground ,red :weight bold))))
   `(magit-signature-untrusted ((t (:foreground ,amber))))
   `(magit-cherry-equivalent ((t (:foreground ,amber))))
   `(magit-cherry-unmatched ((t (:foreground ,green))))
   `(git-commit-summary ((t (:foreground ,ash :weight bold))))
   `(git-commit-overlong-summary ((t (:foreground ,red :weight bold))))
   `(git-commit-nonempty-second-line ((t (:foreground ,red :weight bold))))
   `(git-commit-keyword ((t (:foreground ,amber))))
   `(git-commit-trailer-token ((t (:foreground ,amber))))
   `(git-commit-trailer-value ((t (:foreground ,ash))))
   `(git-commit-comment-heading ((t (:foreground ,amber :slant italic))))
   `(git-commit-comment-file ((t (:foreground ,ash :slant italic))))
   `(git-commit-comment-branch-local ((t (:foreground ,amber))))
   `(git-commit-comment-branch-remote ((t (:foreground ,green))))

   ;;; Hellmacs JVM status (the :lang java mode-line segment, Phase 6.2)
   `(hellmacs-jvm-busy ((t (:foreground ,amber :weight bold))))
   `(hellmacs-jvm-ready ((t (:foreground ,green :weight bold))))
   `(hellmacs-jvm-failed ((t (:foreground ,red :weight bold))))

   ;;; Hellmacs' own faces (defined in core/hellmacs-splash.el and
   ;;; core/hellmacs-ux.el, with these colors as defaults)
   `(hellmacs-splash-sigil ((t (:foreground ,red :weight bold))))
   `(hellmacs-splash-tagline ((t (:foreground ,amber :weight bold))))
   `(hellmacs-splash-altar ((t (:foreground ,green))))
   `(hellmacs-splash-hint ((t (:foreground ,slate))))
   `(hellmacs-fatality ((t (:foreground ,red :weight bold))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'hellmacs)
;;; hellmacs-theme.el ends here
