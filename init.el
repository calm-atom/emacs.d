;; init.el --- Init -*- lexical-binding: t; -*-

;;; Code:

;;; Setting tweaks:

;; No auto-resizing of frames.
(setq frame-inhibit-implied-resize t)

;; Ignore bell sounds.
(setq ring-bell-function #'ignore)

;; Auto-revert dired (the directory editor) when revisiting
;; directories, since they may have changed underneath.
(setq dired-auto-revert-buffer t)

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
