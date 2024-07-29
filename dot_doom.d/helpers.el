(defun helpers/convert-markdown-to-org-links ()
  "Convert markdown-style links to Org mode links in the current buffer."
  (interactive)
  (message "Starting conversion")
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "{\\([^}]+\\)}\\[\\([^]]+\\)\\]" nil t)
      (message "Match found: %s" (match-string 0))
      (replace-match "[[\\1][\\2]]" nil nil)))
  (message "Conversion done"))

(defun helpers/open-default-root-notes-node ()
  "Open the default root notes node."
  (interactive)
  (find-file org-default-notes-file))

(defun helpers/apply-icon-faces ()
  "Apply faces to specified icons in the current buffer."
  (interactive)
  (dolist (pair icon-face-pairs)
    (let ((icon (car pair))
          (face (cdr pair)))
      (font-lock-add-keywords
       nil
       `((,(regexp-quote icon) 0 ,face t))))))

