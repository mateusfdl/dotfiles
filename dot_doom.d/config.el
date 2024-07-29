;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
(load! "helpers.el")
(load! "keybinds.el")

(setq user-full-name "Matheus Lima"
      user-mail-address "matheus.limastack@gmail.com"

      doom-theme 'doom-dracula

      display-line-numbers-type t

      doom-font(font-spec :family "IosevkaSS04 Nerd Font Mono" :size 12)
      doom-themes-enable-bold t
      doom-themes-enable-italic t
      org-directory "~/org/"
      org-default-notes-file (expand-file-name "notes.org" org-directory))

(use-package! projectile
  :defer t
  :init
  (setq projectile-project-search-path '("~/Documents/self/matheus/codes")
        projectile-enable-caching nil))

(use-package! org
  :defer t
  :config (load! (concat doom-user-dir "org-config")))

(use-package! wakatime-mode
  :config
  (setq wakatime-cli-path "/opt/homebrew/bin/wakatime-cli")
  (global-wakatime-mode))

(use-package! org-habit
  :after org
  :config
  (add-to-list 'org-modules 'org-habit))

(use-package! elfeed
  :commands elfeed
  :config
  (map! :map elfeed-search-mode-map
        :n "g r" #'elfeed-update)

  (setq-default elfeed-search-filter "+unread")

  (setq-hook! 'elfeed-search-mode-hook
    elfeed-feeds
    '(
      "https://threedots.tech/index.xml"
      "http://feeds.feedburner.com/codinghorror"
      "http://pragmaticemacs.com/feed/"
      "http://research.swtch.com/feed.atom"
      "https://betweentwoparens.com/rss.xml"
      "https://blog.appsignal.com/feed.xml"
      "https://blog.bigbinary.com/feed.xml"
      "https://blog.cloudflare.com/rss/"
      "https://blog.golang.org/feed.atom"
      "https://blog.gopheracademy.com/index.xml"
      "https://blog.heroku.com/engineering/feed"
      "https://blogs.dropbox.com/tech/feed/"
      "https://cate.blog/feed/"
      "https://dassur.ma/index.xml"
      "https://evilmartians.com/chronicles.atom"
      "https://feeds.feedburner.com/2ality"
      "https://feeds.feedburner.com/GiantRobotsSmashingIntoOtherGiantRobots"
      "https://feeds.feedburner.com/philipwalton"
      "https://herbertograca.com/feed/"
      "https://jvns.ca/atom.xml"
      "https://labs.spotify.com/feed/"
      "https://martinfowler.com/feed.atom"
      "https://oremacs.com/atom.xml"
      "https://otavio.dev/feed/"
      "https://practicalli.github.io/blog/feed.xml"
      "https://tidyfirst.substack.com/feed"
      "https://www.intercom.com/blog/engineering/feed/"
      "https://www.ruby-lang.org/en/feeds/news.rss"
      "https://www.with-emacs.com/rss.xml"
      "https://www.hawkins.io/article/index.xml")))

(add-hook 'org-mode-hook 'helpers/apply-icon-faces)
(add-hook 'org-mode-hook #'font-lock-flush)

