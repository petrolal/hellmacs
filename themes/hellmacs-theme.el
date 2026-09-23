;;; hellmacs-theme.el --- Hellmacs' infernal high-contrast dark theme -*- lexical-binding: t; -*-

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
;; comint REPLs and the Hellmacs splash screen.
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
      (rust    "#3a2600"))              ; lazy search matches
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
