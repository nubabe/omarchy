;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;;
;; nuyan config

;; Watch for changes to uniquify-buffer-name-style

;; (setq uniquify-buffer-name-style 'forward
;;       uniquify-strip-common-suffix t)


(with-eval-after-load 'treesit
  (setq treesit-language-source-alist
        (append treesit-language-source-alist
                '((java "https://github.com/tree-sitter/tree-sitter-java")))))

(unless (treesit-language-available-p 'java)
  (treesit-install-language-grammar 'java))

(defun my/rename-buffer-on-visit ()
  (when buffer-file-name
    (rename-buffer (concat (file-name-nondirectory
                            (directory-file-name
                             (file-name-directory buffer-file-name)))
                           "/"
                           (file-name-nondirectory buffer-file-name)))))

(add-hook 'find-file-hook #'my/rename-buffer-on-visit)
(add-hook 'org-agenda-after-show-hook #'my/rename-buffer-on-visit)


(after! org
  (setq org-latex-packages-alist
        (append '(("" "chemfig" t)
                  ("" "siunitx" t)
                  ("version=4" "mhchem" t)
                  ("" "pgfplots" t))
                org-latex-packages-alist)))

(after! org
  (setq org-global-properties
        '(("BIBLE" . nil)
          ("DATE" . nil))))


(use-package! org-super-agenda
  :after org-agenda
  :config
  (org-super-agenda-mode))


(after! org
  (setq org-modern-mode t
        +org-pretty-mode nil
        org-modern-table nil
        org-modern-todo nil
        org-modern-star 'replace
        org-modern-timestamp nil
        org-modern-block-name nil
        org-modern-tag nil))

;; Adding multiple entries at once
(setq auto-mode-alist
      (append
       '(("\\.jsonc\\'" . jsonc-mode)
         ("\\.java\\'"  . java-ts-mode))
       auto-mode-alist))

(setq display-line-numbers-type 'relative
      line-move-ignore-invisible t
      line-move-visual t
      evil-respect-visual-line-mode t
      visual-line-fringe-indicators '(left-curly-arrow nil)
      user-full-name "Nuyan Barboza")

(after! org
  (setq org-src-window-setup 'current-window))

(defun my/org-split-src-block ()
  "Split the current Org src block at point into two blocks, preserving language."
  (interactive)
  (when (org-in-src-block-p)
    (let* ((lang (nth 0 (org-babel-get-src-block-info))))
      ;; Insert split markers at point
      (insert (format "\n#+END_SRC\n\n#+BEGIN_SRC %s\n" lang)))))

(map! :leader
      :desc "split-src-block"
      "m S" #'my/org-split-src-block)

(defun org-set-deadline-to-next-tagged-appointment (tag)
  "Set DEADLINE of current entry to the next scheduled APPOINTMENT with TAG after now."
  (interactive "sTag: ")
  (let* ((now (current-time))
         (next-date nil))
    (org-map-entries
     (lambda ()
       (let ((todo (org-get-todo-state))
             (sched (org-get-scheduled-time (point))))
         (when (and sched (equal todo "APPOINTMENT") (time-less-p now sched))
           (when (or (null next-date) (time-less-p sched next-date))
             (setq next-date sched)))))
     (concat "TODO=\"APPOINTMENT\"+" tag) 'agenda)
    (if next-date
        (let ((ts (format-time-string "<%Y-%m-%d %a %H:%M>" next-date)))
          (org-deadline nil ts)
          (message "Deadline set to %s" ts))
      (message "No upcoming APPOINTMENT found with tag %s" tag))))



(defun my/open-kitty-in-current-dir ()
  "Open a Kitty terminal in the directory of the current buffer."
  (interactive)
  (let ((default-directory
         (or (file-name-directory (or buffer-file-name default-directory))
             default-directory)))
    (start-process "kitty" nil "kitty" "--directory" default-directory)))

(map! :leader
      :desc "current-dir-in-terminal"
      "o t" #'my/open-kitty-in-current-dir)

;; Set theme
(setq doom-theme 'doom-tokyo-night)

;; Auto-save visited buffers
(auto-save-visited-mode 1)

;; Safe themes
;; (setq custom-safe-themes
;;       '("4594d6b9753691142f02e67b8eb0fda7d12f6cc9f1299a49b819312d6addad1d"
;;         "34cf3305b35e3a8132a0b1bdf2c67623bc2cb05b125f8d7d26bd51fd16d547ec"
;;         default))

;; Org directory and basic settings
(setq org-directory "~/files/org"
      org-agenda-files (cons
                        "~/files/org"
                        (seq-filter #'file-directory-p
                                    (directory-files-recursively
                                     "~/org" ".*" t
                                     (lambda (dir) (not (string-match-p "/\\." dir))))))
      org-archive-location "archive/archive.org::"
      org-export-backends '(ascii beamer html icalendar latex md odt)
      org-log-done 'time
      org-log-into-drawer t
      org-log-reschedule 'note
      org-modules '(ol-bibtex org-habit)
      org-todo-repeat-to-state t
      org-attach-method 'mv
      org-agenda-show-future-repeats nil
      org-refile-use-outline-path 'buffer-name)

(defun my/org-refile-verify-target ()
  "Exclude archived headings from refile targets."
  (not (string-match-p "/archive/" (buffer-file-name (buffer-base-buffer)))))

(setq org-refile-target-verify-function #'my/org-refile-verify-target)


;; Org agenda settings
(after! org
  (setq org-agenda-custom-commands
        '(("p" "Project Default"
           ((todo "TODO"
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                   (org-agenda-hide-tags-regexp "skip\\|pg\\|technik")))
            (agenda ""
                    ((org-agenda-skip-function (lambda ()
                                                 (or
                                                  (org-agenda-skip-entry-if 'nottodo '("APPOINTMENT" "TODO"))
                                                  )))))))
          ("P" "Project TODOs" todo "TODO"
           ((org-agenda-hide-tags-regexp "skip\\|pg\\|technik")))
          ("c" "Calendar" agenda ""
           ((org-agenda-skip-function
             (lambda ()
               (let ((tags (org-get-tags-at))
                     (end (save-excursion (org-end-of-subtree t))))
                 (or
                  ;; 1. Skip 'skip' unless it has '@nuyan'
                  (when (and (member "skip" tags)
                             (not (or (member "@nuyan" tags)
                                      (member "@alle" tags))))
                    end)
                  ;; 2. Skip if it’s not an APPOINTMENT
                  (org-agenda-skip-entry-if 'nottodo '("APPOINTMENT" "TODO"))))))
            (org-agenda-hide-tags-regexp "@nuyan\\|skip")))
          ("t" "todo" todo "TODO"
           ((org-agenda-skip-function
             (lambda ()
               (let ((tags (org-get-tags-at))
                     (end (save-excursion (org-end-of-subtree t))))
                 (or
                  ;; 1. Skip 'skip' unless it has '@nuyan'
                  (when (and (member "skip" tags)
                             (not (or (member "@nuyan" tags)
                                      (member "@alle" tags))))
                    end)
                  ;; 2. Skip if it’s not an APPOINTMENT
                  (org-agenda-skip-entry-if 'scheduled 'deadline)))))
            (org-agenda-overriding-header "TODOs")))
          ("k" "klausuren" todo ""
           ((org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp ".*:klausur:.*"))
            (org-agenda-overriding-header "Klausuren")
            (org-agenda-sorting-strategy '((todo scheduled-up)))
            (org-agenda-prefix-format '((todo . " %s ")))))
          ("g" "prayer" todo "PRAY"
           ((org-agenda-overriding-header "Prayer"))))
        org-agenda-format-date "%F - %A"
        org-agenda-time-grid '((daily weekly today require-timed remove-match)
                               (800 1000 1200 1400 1600 1800 2000)
                               "......"
                               "----------------")
        org-agenda-time-leading-zero t
        org-agenda-timerange-leaders '("" "%d/%d: ")
        org-agenda-prefix-format '((agenda . " %-7s%-12t")
                                   (todo   . " %i")
                                   (tags   . " %i %-12:c")
                                   (search . " %i %-12:c"))
        org-agenda-deadline-leaders '("D: " "In%3dd:" "%2dd ago: ")
        org-agenda-scheduled-leaders '("" "%dd ago:")
        org-agenda-skip-deadline-prewarning-if-scheduled t
        org-agenda-use-time-grid t
        org-agenda-start-on-weekday 1
        org-agenda-span 'week
        org-agenda-start-day "0d"
        org-agenda-hide-tags-regexp "skip"
        org-agenda-sorting-strategy '((agenda habit-down time-up urgency-down category-keep)
                                      (todo urgency-down category-keep)
                                      (tags urgency-down category-keep)
                                      (search category-keep))
        org-agenda-window-setup 'current-window))

;; Org capture templates
(after! org
  (setq org-capture-templates
        '(("c" "Capture Stuff" entry
           (file+olp "~/org/inbox.org" "Capture")
           "* STUFF %?")
          ("j" "Journal" entry
           (file+olp+datetree "~/org/journal.org")
           "* %(format-time-string \"%H:%M\")\n** Gratitude\n- %?\n")
          ("b" "bible" entry
           (file+olp+datetree "~/documents/jesus/inbox.org")
           "* %^{title/topic}\n%?")
          ("t" "Technik" entry
           (file+olp "~/org/technik.org" "Events")
           ""))))

;; Org tags and TODO keywords/faces

(after! org
  (setq org-tag-alist '(("@nuyan" . ?n)
                        ("skip" . ?s)
                        ("pg" . ?p)
                        ("technik" . ?t)
                        ("klausur" . ?k))
        org-tags-column 0))

(after! org
  (setq org-todo-keywords
        '((sequence "STUFF(I)" "WAIT(w/!)" "TODO(t/!)" "APPOINTMENT(a)"
           "SOMEDAY(s)" "INFO(i)" "BLOCK(b)" "PROJ(p)"
           "|"
           "DONE(d)" "DELEGATED(D@)" "CANCELED(c)")
          (sequence "PRAY(y/!)" "|" "ANSWERED(@)")))

  (setq org-todo-keyword-faces
        `(("WAIT" . +org-todo-onhold)
          ("PROJ" . +org-todo-project)
          ("TODO" . +org-todo-active)
          ("APPOINTMENT" . +org-todo-active)
          ("STUFF" . +org-todo-cancel)
          ("PRAY" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-blue nil t)))
          ("ANSWERED" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-magenta nil t)))))

  (add-hook! 'doom-load-theme-hook
    (setq org-todo-keyword-faces
          `(("WAIT" . +org-todo-onhold)
            ("PROJ" . +org-todo-project)
            ("TODO" . +org-todo-active)
            ("APPOINTMENT" . +org-todo-active)
            ("STUFF" . +org-todo-cancel)
            ("PRAY" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-blue nil t)))
            ("ANSWERED" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-magenta nil t)))))))

(after! org-modern (setq org-modern-todo-faces
                         `(("WAIT" . +org-todo-onhold)
                           ("PROJ" . +org-todo-project)
                           ("TODO" . +org-todo-active)
                           ("APPOINTMENT" . +org-todo-active)
                           ("STUFF" . +org-todo-cancel)
                           ("PRAY" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-blue nil t)))
                           ("ANSWERED" . (:inherit +org-todo-active :foreground ,(face-foreground 'ansi-color-magenta nil t))))))

(after! org
  (setq org-todo-keyword-alist-for-agenda nil
        org-todo-keywords-for-agenda nil))

;; Org heading sizes
(custom-set-faces!
  '(org-level-1 :height 1.5 :weight bold)
  '(org-level-2 :height 1.3 :weight bold)
  '(org-level-3 :height 1.2 :weight bold)
  '(org-level-4 :height 1.1 :weight bold)
  '(org-level-5 :height 1.1 :weight bold)
  '(org-level-6 :height 1.0 :weight bold)
  '(org-level-7 :height 1.0 :weight bold)
  '(org-level-8 :height 1.0 :weight bold))

(setq org-file-apps '((remote . emacs)
                      (auto-mode . emacs)
                      (directory . "kitty -d %s")
                      ("\\.mm\\'" . default)
                      ("\\.x?html?\\'" . default)
                      ("\\.pdf\\'" . "xdg-open %s")
                      ("\\.mp4\\'" . "xdg-open %s")
                      ("\\.ggb\\'" . "xdg-open %s")
                      ("\\.odg\\'" . "xdg-open %s")
                      ("\\.docx\\'" . "xdg-open %s")
                      ))

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "CaskaydiaMono Nerd Font" :size 15 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "CaskaydiaMono Nerd Font" :size 13)
      nerd-icons-font-family "CaskaydiaMono Nerd Font")
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-tokyo-night)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
;; (setq org-directory "~/userdata/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
