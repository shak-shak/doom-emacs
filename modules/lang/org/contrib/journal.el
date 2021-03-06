;;; lang/org/contrib/journal.el -*- lexical-binding: t; -*-
;;;###if (featurep! +journal)

(use-package! org-journal
  :defer t
  :preface
  ;; HACK `org-journal' adds a `magic-mode-alist' entry for detecting journal
  ;;      files, but this causes us lazy loaders a big problem: an unacceptable
  ;;      delay on the first file the user opens, because calling the autoloaded
  ;;      `org-journal-is-journal' pulls all of `org' with it. So, we replace it
  ;;      with our own, extra layer of heuristics.
  (setq magic-mode-alist (assq-delete-all 'org-journal-is-journal magic-mode-alist))
  (add-to-list 'magic-mode-alist '(+org-journal-p . org-journal-mode))

  (defun +org-journal-p ()
    (when buffer-file-name
      (and (file-in-directory-p
            buffer-file-name (expand-file-name org-journal-dir org-directory))
           (delq! '+org-journal-p magic-mode-alist 'assq)
           (require 'org-journal nil t)
           (org-journal-is-journal))))

  ;; HACK `org-journal-is-journal' doesn't anticipate symlinks, and won't
  ;;      correctly detect journal files in an unresolved `org-directory' or
  ;;      `org-journal'. `org-journal-dir' must be given the `file-truename'
  ;;      treatment later, as well.
  (defadvice! +org--journal-resolve-symlinks-a (orig-fn)
    :around #'org-journal-is-journal
    (let ((buffer-file-name (file-truename buffer-file-name)))
      (funcall orig-fn)))

  :init
  ;; HACK `org-journal-dir' is surrounded with setters and `auto-mode-alist'
  ;;      magic which makes it difficult to create an better default for Doom
  ;;      users. We set this here so we can detect user-changes to it later.
  (setq org-journal-dir "journal/"
        org-journal-cache-file (concat doom-cache-dir "org-journal")
        ;; Doom opts for an "open in a popup or here" strategy as a default.
        ;; Open in "other window" is less predictable, and can replace a window
        ;; we wanted to keep visible.
        org-journal-find-file #'find-file)

  :config
  (setq org-journal-dir (file-truename (expand-file-name org-journal-dir org-directory)))

  (set-popup-rule! "^\\*Org-journal search" :select t :quit t)

  (map! (:map org-journal-mode-map
         :n "]f"  #'org-journal-open-next-entry
         :n "[f"  #'org-journal-open-previous-entry
         :n "C-n" #'org-journal-open-next-entry
         :n "C-p" #'org-journal-open-previous-entry)
        (:map org-journal-search-mode-map
         "C-n" #'org-journal-search-next
         "C-p" #'org-journal-search-previous)
        :localleader
        (:map org-journal-mode-map
         "c" #'org-journal-new-entry
         "d" #'org-journal-new-date-entry
         "n" #'org-journal-open-next-entry
         "p" #'org-journal-open-previous-entry
         (:prefix "s"
          "s" #'org-journal-search
          "f" #'org-journal-search-forever
          "F" #'org-journal-search-future
          "w" #'org-journal-search-calendar-week
          "m" #'org-journal-search-calendar-month
          "y" #'org-journal-search-calendar-year))
        (:map org-journal-search-mode-map
         "n" #'org-journal-search-next
         "p" #'org-journal-search-prev)))
