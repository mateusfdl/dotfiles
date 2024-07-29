;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el
(package! all-the-icons)
(package! elfeed)
(package! graphviz-dot-mode)
(package! copilot
  :recipe (:host github :repo "copilot-emacs/copilot.el" :files ("*.el" "dist")))
(package! wakatime-mode)
