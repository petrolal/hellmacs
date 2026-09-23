;;; hellmacs-keybinds.el --- The C-c leader -*- lexical-binding: t; -*-

;; Hellmacs uses Emacs' default keybindings -- no evil, no modal
;; editing (see "Keybinding policy" in docs/roadmap.md). Its own
;; commands live under `C-c', the prefix Emacs reserves for users,
;; laid out like Doom's non-evil leader: `C-c h' Hellmacs, `C-c f'
;; file, `C-c b' buffer, `C-c s' search, `C-c w' window, `C-c q' quit.
;;
;; This file only provides `hellmacs-leader-def', which every module and
;; your own config.el use to bind into that layout. It's in core, not a
;; module, so it exists no matter which modules are enabled. The
;; default bindings themselves live in the `:config default' module.
;;
;; No keybinding package is needed: Emacs 29's `keymap-set' covers
;; everything once there are no evil states to juggle.

;;; Code:

(defun hellmacs-leader-def (&rest bindings)
  "Bind BINDINGS, alternating KEY DEF pairs, under the `C-c' leader.

KEY is relative to `C-c', in `keymap-set' syntax (\"f f\" means
`C-c f f'). DEF is one of:
  - a command
  - (DESCRIPTION . COMMAND), to also give which-key a label
  - a string, to label KEY as a prefix group (\"file\" for `C-c f')

  (hellmacs-leader-def
    \"f\"   \"file\"
    \"f r\" \='(\"recent file\" . consult-recent-file))

Bindings go into `mode-specific-map', the keymap Emacs itself puts on
`C-c', so bindings made there by the user or by other packages keep
working alongside Hellmacs'."
  (while bindings
    (let ((key (pop bindings))
          (def (pop bindings)))
      (keymap-set mode-specific-map key
                  (if (stringp def)
                      ;; (LABEL . KEYMAP) is still a prefix to Emacs, and
                      ;; which-key displays LABEL for it.
                      (let ((map (keymap-lookup mode-specific-map key)))
                        (cons def (if (keymapp map) map (make-sparse-keymap))))
                    def)))))

(provide 'hellmacs-keybinds)
;;; hellmacs-keybinds.el ends here
