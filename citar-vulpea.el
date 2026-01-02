;;; citar-vulpea.el --- Minor mode integrating Citar and Vulpea -*- lexical-binding: t -*-

;; Copyright (C) 2026 Fabrizio Contigiani

;; Author: Fabrizio Contigiani
;; Maintainer: Fabrizio Contigiani
;; Homepage: https://github.com/fabcontigiani/citar-vulpea
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.2") (citar "1.4") (vulpea "2.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A minor-mode integrating 'citar' and 'vulpea' to create and manage
;; bibliographic notes.
;;
;; Citar-Vulpea integrates the Citar bibliography package with the Vulpea
;; note-taking system.  Citar lets you browse and act on bibliographic data
;; in BibTeX, BibLaTeX or JSON format.  Vulpea is an efficient database layer
;; for org-mode notes.  Combining these packages enables linking notes in your
;; Vulpea collection to your bibliography, providing a solution for documenting
;; literature reviews.
;;
;; To enable, call `citar-vulpea-mode' or add to your init file:
;;
;;   (citar-vulpea-mode 1)

;;; Code:

(require 'citar)
(require 'vulpea)
(require 'org)

(eval-when-compile
  (require 'subr-x))

;;; Customization

(defgroup citar-vulpea ()
  "Creating and accessing bibliography files with Citar and Vulpea."
  :group 'citar
  :link '(url-link :tag "Homepage" "https://github.com/fabcontigiani/citar-vulpea/"))

(defcustom citar-vulpea-keyword "bib"
  "Vulpea tag (filetag) to indicate bibliographical notes.
This minimizes the search space for connecting notes to a bibliography."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-refs-property "ROAM_REFS"
  "Property name used to store citation keys in notes.
The property value should contain cite keys prefixed with @, e.g., @smith2020.
Multiple keys can be separated by spaces."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-note-title-template
  "${author}, ${title}"
  "Template for formatting new note titles.
Supports citar template variables like ${author}, ${title}, ${date}."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-subdir nil
  "Subdirectory for bibliographic notes.
When nil, notes are stored in `vulpea-default-notes-directory'.
When a string, notes are stored in that subdirectory."
  :group 'citar-vulpea
  :type '(choice (const :tag "Default directory" nil)
                 (string :tag "Subdirectory")))

;;; Notes source configuration

(defconst citar-vulpea-notes-config
  (list :name "Vulpea Notes"
        :category 'vulpea-note
        :items #'citar-vulpea--get-candidates
        :hasitems #'citar-vulpea--has-notes
        :open #'citar-vulpea-open-note
        :create #'citar-vulpea--create-note)
  "Citar notes source configuration for Vulpea.")

(defvar citar-notes-source)
(defvar citar-notes-sources)

;;; Internal functions

(defun citar-vulpea--note-property (note property)
  "Get value of PROPERTY from NOTE.
Lookup PROPERTY in the properties alist of NOTE."
  (cdr (assoc property (vulpea-note-properties note))))

(defun citar-vulpea--parse-refs (refs-string)
  "Parse REFS-STRING into a list of citation keys.
REFS-STRING contains @-prefixed keys separated by spaces."
  (when refs-string
    (let ((keys nil))
      (with-temp-buffer
        (insert refs-string)
        (goto-char (point-min))
        (while (re-search-forward "@\\([[:alnum:]_:-]+\\)" nil t)
          (push (match-string 1) keys)))
      (nreverse keys))))

(defun citar-vulpea--get-notes-for-key (key)
  "Get vulpea notes with refs property containing KEY."
  (vulpea-db-query
   (lambda (note)
     (when-let ((refs (citar-vulpea--note-property note citar-vulpea-refs-property)))
       (let ((keys (citar-vulpea--parse-refs refs)))
         (and keys
              (member key keys)
              (seq-contains-p (vulpea-note-tags note) citar-vulpea-keyword)))))))

(defun citar-vulpea--get-all-bib-notes ()
  "Get all vulpea notes tagged with `citar-vulpea-keyword'."
  (vulpea-db-query
   (lambda (note)
     (and (citar-vulpea--note-property note citar-vulpea-refs-property)
          (seq-contains-p (vulpea-note-tags note) citar-vulpea-keyword)))))

(defun citar-vulpea--get-notes (&optional keys)
  "Return hash table mapping citation KEYS to lists of vulpea notes.
If KEYS is nil, return all notes with bibliography references."
  (let ((notes-table (make-hash-table :test 'equal))
        (all-notes (citar-vulpea--get-all-bib-notes)))
    (dolist (note all-notes)
      (when-let* ((refs (citar-vulpea--note-property note citar-vulpea-refs-property))
                  (note-keys (citar-vulpea--parse-refs refs)))
        (dolist (key note-keys)
          (when (or (null keys) (member key keys))
            (push note (gethash key notes-table))))))
    notes-table))

(defun citar-vulpea--has-notes ()
  "Return function to check if a citekey has notes.
Used by citar to determine which entries have associated notes."
  (let ((notes-table (citar-vulpea--get-notes)))
    (unless (hash-table-empty-p notes-table)
      (lambda (citekey) (and (gethash citekey notes-table) t)))))

(defun citar-vulpea--get-candidates (&optional keys)
  "Return hash table of citekey to candidate strings for KEYS.
Each candidate is formatted for citar's completion interface."
  (let ((notes-table (citar-vulpea--get-notes keys))
        (candidates (make-hash-table :test 'equal)))
    (maphash
     (lambda (key notes)
       (dolist (note notes)
         (push (concat (propertize (vulpea-note-id note) 'invisible t)
                       " "
                       (propertize (vulpea-note-title note) 'face 'citar))
               (gethash key candidates))))
     notes-table)
    candidates))

(defun citar-vulpea--format-note-title (citekey)
  "Generate note title for CITEKEY using `citar-vulpea-note-title-template'."
  (when-let ((entry (citar-get-entry citekey)))
    (citar-format--entry citar-vulpea-note-title-template entry)))

(defun citar-vulpea--create-note (citekey &optional _entry)
  "Create a new bibliographic note for CITEKEY.
ENTRY is the bibliography entry (unused, fetched from citar)."
  (let* ((title (or (citar-vulpea--format-note-title citekey)
                    (read-string "Title: ")))
         (file-name-template (when citar-vulpea-subdir
                               (concat citar-vulpea-subdir "/${slug}.org")))
         (note (vulpea-create
                title
                file-name-template
                :tags (list citar-vulpea-keyword)
                :properties (list (cons citar-vulpea-refs-property
                                        (concat "@" citekey))))))
    (when note
      (vulpea-visit note))))

;;; Interactive commands

;;;###autoload
(defun citar-vulpea-open-note (candidate)
  "Open vulpea note from CANDIDATE string.
CANDIDATE is a string with the note ID as an invisible prefix."
  (let ((id (car (split-string (substring-no-properties candidate)))))
    (when-let ((note (vulpea-db-get-by-id id)))
      (vulpea-visit note))))

;;;###autoload
(defun citar-vulpea-find-citation ()
  "Find notes that cite a bibliographic reference.
Prompts to select from bibliography entries that have citations in notes."
  (interactive)
  (let* ((notes-table (citar-vulpea--get-notes))
         (keys-with-notes (hash-table-keys notes-table)))
    (if (null keys-with-notes)
        (user-error "No citations found in Vulpea notes")
      (let* ((citekey (citar-select-ref
                       :filter (lambda (key) (member key keys-with-notes))))
             (notes (gethash citekey notes-table)))
        (if (= (length notes) 1)
            (vulpea-visit (car notes))
          (let ((note (vulpea-select-from "Select note" notes
                                          :require-match t)))
            (vulpea-visit note)))))))

;;;###autoload
(defun citar-vulpea-add-reference ()
  "Add a citation reference to the current note.
Prompts to select a bibliography entry and adds it to the ROAM_REFS property."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((current-refs (org-entry-get nil citar-vulpea-refs-property))
         (current-keys (citar-vulpea--parse-refs current-refs))
         (citekey (citar-select-ref
                   :filter (lambda (key) (not (member key current-keys)))))
         (new-ref (concat "@" citekey))
         (new-refs (if current-refs
                       (concat current-refs " " new-ref)
                     new-ref)))
    (org-entry-put nil citar-vulpea-refs-property new-refs)
    ;; Ensure the bib tag is present
    (let ((tags (org-get-tags nil t)))
      (unless (member citar-vulpea-keyword tags)
        (org-set-tags (cons citar-vulpea-keyword tags))))
    (message "Added reference: %s" citekey)))

;;;###autoload
(defun citar-vulpea-remove-reference ()
  "Remove a citation reference from the current note.
If only one reference remains, also removes the bibliography tag."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((current-refs (org-entry-get nil citar-vulpea-refs-property))
         (current-keys (citar-vulpea--parse-refs current-refs)))
    (if (null current-keys)
        (user-error "No references in current note")
      (let* ((key-to-remove (if (= (length current-keys) 1)
                                (car current-keys)
                              (completing-read "Remove reference: " current-keys nil t)))
             (remaining-keys (delete key-to-remove current-keys)))
        (if remaining-keys
            (org-entry-put nil citar-vulpea-refs-property
                           (mapconcat (lambda (k) (concat "@" k)) remaining-keys " "))
          ;; No refs left, remove property and tag
          (org-entry-delete nil citar-vulpea-refs-property)
          (let ((tags (org-get-tags nil t)))
            (org-set-tags (delete citar-vulpea-keyword tags))))
        (message "Removed reference: %s" key-to-remove)))))

;;;###autoload
(defun citar-vulpea-dwim ()
  "Smart action for current bibliographic note.
If the current note has references, open citar for those entries.
Otherwise, offer to add a reference."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((refs (org-entry-get nil citar-vulpea-refs-property))
         (keys (citar-vulpea--parse-refs refs)))
    (if keys
        (let ((key (if (= (length keys) 1)
                       (car keys)
                     (completing-read "Select reference: " keys nil t))))
          (citar-open (list key)))
      (when (yes-or-no-p "No references in current note.  Add one? ")
        (citar-vulpea-add-reference)))))

;;; Minor mode

(defvar citar-vulpea--orig-source nil
  "Original citar-notes-source before enabling citar-vulpea-mode.")

(defun citar-vulpea--setup ()
  "Setup citar-vulpea integration."
  (setq citar-vulpea--orig-source citar-notes-source)
  (citar-register-notes-source 'citar-vulpea citar-vulpea-notes-config)
  (setq citar-notes-source 'citar-vulpea))

(defun citar-vulpea--teardown ()
  "Teardown citar-vulpea integration."
  (setq citar-notes-source citar-vulpea--orig-source)
  (citar-remove-notes-source 'citar-vulpea))

;;;###autoload
(define-minor-mode citar-vulpea-mode
  "Toggle integration between Citar and Vulpea.
When enabled, citar uses Vulpea as its notes backend, allowing you to
create and access bibliography notes stored in your Vulpea database."
  :global t
  :group 'citar-vulpea
  :lighter " citar-vulpea"
  (if citar-vulpea-mode
      (citar-vulpea--setup)
    (citar-vulpea--teardown)))

(provide 'citar-vulpea)
;;; citar-vulpea.el ends here
