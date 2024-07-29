;;; $DOOMDIR/org-config.el -*- lexical-binding: t; -*-

(setq 
      icon-face-pairs
            '(("" . 'nerd-icons-red)
              ("" . 'nerd-icons-orange)
              ("" . 'nerd-icons-blue)
              ("" . 'nerd-icons-purple)
              ("󰛦" . 'nerd-icons-blue))

      org-habit-graph-column 50
      org-enforce-todo-dependencies t
      org-enforce-todo-checkbox-dependencies t
      org-log-done 'time
      org-log-into-drawer t
      org-hide-emphasis-markers t
      org-habit-show-habits t
;;      org-habit-show-all-today t
      org-agenda-folder (concat org-directory "agenda/")
      org-agenda-files (list (expand-file-name "livefire.org" org-agenda-folder)
                             (expand-file-name "kairos.org" org-agenda-folder)
                             (expand-file-name "habits.org" org-agenda-folder))
     org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "|" "DONE(d)" "CANCELLED(c)")
                        (sequence "[ ](T)" "|" "[-](I)" "|" "[X](D)" "[@](C)"))
     org-todo-keyword-faces
                       '(("TODO" . (:foreground "Orange" :weight bold))
                        ("INPROGRESS" . (:foreground "Yellow" :weight bold))
                        ("DONE" . (:foreground "Green" :weight bold))
                        ("CANCELLED" . (:foreground "Red" :weight bold))))
