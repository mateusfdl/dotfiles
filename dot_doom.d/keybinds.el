(map! :leader
  (:prefix ("o" . "Org Mode")
   :desc "Open elfeed" "e" #'elfeed
   :desc "Org Node" "h" #'helpers/open-default-root-notes-node))
