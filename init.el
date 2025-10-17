;; init.el --- Init -*- lexical-binding: t; -*-

;;; Code:

;;; Setting tweaks:

;; Disable splash screen and startup message.
(setq inhibit-startup-message t) 
(setq initial-scratch-message nil)

;; No auto-resizing of frames.
(setq frame-inhibit-implied-resize t)

;; Ignore bell sounds.
(setq ring-bell-function #'ignore)

;; Scroll Eshell to the bottom when new output is added.
(setq eshell-scroll-to-bottom-on-input 'this)

;; The safest, but slowest method for creating backups.
(setq backup-by-copying t)

;; Avoid cluttering up project directories with backup files by saving
;; them to the same place.
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))

;; "M-x customize" can tweak Emacs Lisp variables via a graphical
;; interface, but those tweaks are normally saved directly to your
;; hand-edited `init.el'.  I like a clean `init.el', so I write those
;; customizations to a different file instead.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;; Emacs Lisp files can be byte-compiled into `.elc' files, which run
;; faster.  By default Emacs prefers `.elc' to `.el' in all cases,
;; causing occasional annoyances if you make a change to an Emacs Lisp
;; file but forget to byte-compile it.  `load-prefer-newer' always
;; prefers the last-edited file, preventing this problem.
(setq load-prefer-newer t)

;; Avoid tabs when possible.
(setq-default indent-tabs-mode nil)

;; Display line numbers in programming language modes.
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Respect color escape sequences.  Particularly useful for "M-x
;; compile" with modern programming languages that use colors to
;; convey information.
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

;; Initialize package.el for loading third-party packages.  Also set
;; up package.el to accept packages from the MELPA package archives,
;; the largest package repository for Emacs.
(require 'package)
(package-initialize)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(when (< emacs-major-version 29)
  (unless (package-installed-p 'use-package)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install 'use-package)))

;; Hide buffer with byte compiler warnings when installing packages
(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;;; Packages:

;; Delete selected test upon text insertion.
(use-package delsel
  :ensure nil ; no need to install it as it is built-in
  :hook (after-init . delete-selection-mode))

;; When there are conflicting names in your buffer-selector ("C-x b"),
;; `uniquify' disambiguates them by prepending the directory.
(use-package uniquify
  :config
  (setq uniquify-buffer-name-style 'forward))

;; When using Mac OSX or Linux, you likely want your shell environment
;; path available to Emacs so that Emacs can locate your custom
;; utilities.  This is helpful if you use your PATH variable for LSP
;; servers, CLI tools, language environments etc.  Windows users can
;; effectively ignore this package.
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :ensure t
  :config
  (exec-path-from-shell-initialize))

;; When the minibuffer is open and you're searching for some text,
;; Emacs can be very persnickety about the order in which you type.
;; Orderless laxes this behavior so the search is "fuzzier"; you'll
;; see results more often even if you type things in the wrong order.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Emacs ships with several completion engines, but none are as
;; flexible as Vertico.  This is the secret sauce that powers the
;; Emacs "Command Palette", enabling tab-completion when using "M-x
;; command", `project-find-file', and other minibuffer commands.
(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode))

;; Marginalia adds, well, marginalia to the Emacs minibuffer,
;; extending Vertico with a ton of rich information.
(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode))

;; Persist minibuffer history over Emacs restarts.  Vertico uses this
;; to sort based on history.
(use-package savehist
  :ensure nil ; it is built-in
  :hook (after-init . savehist-mode))

;; Where Vertico is a completion engine for your Emacs minibuffer,
;; Corfu is a completion engine for your source code.  This package
;; takes the data from things like LSP or Dabbrev and puts those
;; results in a convenient autocomplete.
(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (:map corfu-map ("<tab>" . corfu-complete))
  :config
  (setq tab-always-indent 'complete)
  (setq corfu-preview-current nil)
  (setq corfu-min-width 20)

  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode 1) ; shows documentation after `corfu-popupinfo-delay'

  ;; Sort by input history (no need to modify `corfu-sort-function').
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

;; Imporve the behavior and look of dired.
(use-package dired
  :ensure nil
  :commands (dired)
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq dired-dwim-target t))
  (setq dired-auto-revert-buffer t)

(use-package dired-subtree
  :ensure t
  :after dired
  :bind
  ( :map dired-mode-map
    ("<tab>" . dired-subtree-toggle)
    ("TAB" . dired-subtree-toggle)
    ("<backtab>" . dired-subtree-remove)
    ("S-TAB" . dired-subtree-remove))
  :config
  (setq dired-subtree-use-backgrounds nil))

;; Emacs includes Tree-sitter support as of version 29, but does not
;; bundle Tree-sitter grammars via the usual installation methods.
;; That means that if you want to use a Tree-sitter major mode, you
;; must first install the respective language grammar.  `treesit-auto'
;; is a handy package that manages this extra step for you, prompting
;; the installation of Tree-sitter grammars when necessary.
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Font and theme.
;; Remember to do M-x and run `nerd-icons-install-fonts' to get the
;; font files.  Then restart Emacs to see the effect.
(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))
