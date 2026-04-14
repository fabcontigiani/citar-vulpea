;;; citar-vulpea.el --- Minor mode integrating Citar and Vulpea -*- lexical-binding: t -*-

;; Copyright (C) 2026 Fabrizio Contigiani

;; Author: Fabrizio Contigiani <fabcontigiani@gmail.com>
;; Maintainer: Fabrizio Contigiani <fabcontigiani@gmail.com>
;; URL: https://github.com/fabcontigiani/citar-vulpea
;; Version: 0.1.1
;; Package-Requires: ((emacs "27.2") (citar "1.4") (vulpea "2.0"))
;; Keywords: bibliography, notes, vulpea

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
(require 'seq)

(eval-when-compile
  (require 'subr-x))

;;; Customization

(defgroup citar-vulpea ()
  "Creating and accessing bibliography notes with Citar and Vulpea."
  :group 'citar
  :link '(url-link :tag "GitHub" "https://github.com/fabcontigiani/citar-vulpea/"))

(defcustom citar-vulpea-keyword "bib"
  "Vulpea tag (filetag) to indicate bibliographical notes.
This minimizes the search space for connecting notes to a bibliography."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-references-property "REFERENCES"
  "Property name used to store citation keys in notes.
The property should contain cite keys prefixed with @, e.g., @smith2020.
Multiple keys can be separated by spaces."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-note-title-template
  "${author}, ${title}"
  "Template for formatting new note titles.
Supports citar template variables like ${author}, ${title}, ${date}."
  :group 'citar-vulpea
  :type 'string)

(defcustom citar-vulpea-notes-directory nil
  "Directory for bibliographic notes.
When nil, notes are stored in `vulpea-default-notes-directory'.
When a string, notes are stored in that directory."
  :group 'citar-vulpea
  :type '(choice (const :tag "Default directory" nil)
                 (string :tag "Path")))

;;; Notes source configuration

(defconst citar-vulpea-notes-config
  (list :name "Vulpea Notes"
        :category 'vulpea-note
        :items #'citar-vulpea--get-candidates
        :hasitems #'citar-vulpea--has-notes
        :open #'citar-vulpea--open-note
        :create #'citar-vulpea--create-note)
  "Citar notes source configuration for Vulpea.")

;;; Internal functions

(defun citar-vulpea--note-property (note property)
  "Get value of PROPERTY from NOTE.
Lookup PROPERTY in the properties alist of NOTE, handling both
string and symbol keys, and case-insensitivity."
  (cdr (assoc-string property (vulpea-note-properties note) t)))

(defun citar-vulpea--get-ref-property ()
  "Get the reference property for the note at point.
Ensures we look at the correct entry (heading or file-level)."
  (save-excursion
    (org-back-to-heading-or-point-min t)
    (org-entry-get nil citar-vulpea-references-property)))

(defun citar-vulpea--set-ref-property (value)
  "Set the reference property for the note at point to VALUE.
Ensures we update the correct entry (heading or file-level) and
prefer property drawers over keywords."
  (save-excursion
    (org-back-to-heading-or-point-min t)
    (if (org-string-nw-p value)
        (org-set-property citar-vulpea-references-property value)
      (org-delete-property citar-vulpea-references-property))))

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


(defun citar-vulpea--get-all-bib-notes ()
  "Get all vulpea notes tagged with `citar-vulpea-keyword'.
If `citar-vulpea-keyword' is nil or an empty string, return all
notes with the reference property."
  (vulpea-db-query
   (lambda (note)
     (and (citar-vulpea--note-property note citar-vulpea-references-property)
          (or (not (org-string-nw-p citar-vulpea-keyword))
              (seq-contains-p (vulpea-note-tags note) citar-vulpea-keyword))))))

(defun citar-vulpea--get-notes (&optional keys)
  "Return hash table mapping citation KEYS to lists of vulpea notes.
If KEYS is nil, return all notes with bibliography references."
  (let ((notes-table (make-hash-table :test 'equal))
        (all-notes (citar-vulpea--get-all-bib-notes)))
    (dolist (note all-notes)
      (when-let* ((refs (citar-vulpea--note-property note citar-vulpea-references-property))
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
                       (vulpea-note-title note))
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
         (file-name-template (when citar-vulpea-notes-directory
                               (concat citar-vulpea-notes-directory "/${slug}.org")))
         (note (vulpea-create
                title
                file-name-template
                :tags (list citar-vulpea-keyword)
                :properties (list (cons citar-vulpea-references-property
                                        (concat "@" citekey))))))
    (when note
      (vulpea-visit note))))

(defun citar-vulpea--open-note (candidate)
  "Open vulpea note from CANDIDATE string.
CANDIDATE is a string with the note ID as an invisible prefix."
  (let ((id (car (split-string (substring-no-properties candidate)))))
    (when-let ((note (vulpea-db-get-by-id id)))
      (vulpea-visit note))))

;;; Interactive commands

;;;###autoload
(defun citar-vulpea-add-reference ()
  "Add a citation reference to the current note.
Prompts to select a bibliography entry and adds it to the reference property."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((current-refs (citar-vulpea--get-ref-property))
         (current-keys (citar-vulpea--parse-refs current-refs))
         (citekey (citar-select-ref
                   :filter (lambda (key) (not (member key current-keys)))))
         (new-ref (concat "@" citekey))
         (new-refs (if (and current-refs (> (length current-refs) 0))
                       (concat current-refs " " new-ref)
                     new-ref)))
    (citar-vulpea--set-ref-property new-refs)
    ;; Ensure the bib tag is present
    (vulpea-buffer-tags-add (list citar-vulpea-keyword))
    (message "Added reference: %s" citekey)))

;;;###autoload
(defun citar-vulpea-remove-reference ()
  "Remove a citation reference from the current note.
If only one reference remains, also removes the bibliography tag."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((current-refs (citar-vulpea--get-ref-property))
         (current-keys (citar-vulpea--parse-refs current-refs)))
    (if (null current-keys)
        (user-error "No references in current note")
      (let* ((key-to-remove (if (= (length current-keys) 1)
                                (car current-keys)
                              (completing-read "Remove reference: " current-keys nil t)))
             (remaining-keys (delete key-to-remove current-keys)))
        (if remaining-keys
            (citar-vulpea--set-ref-property
             (mapconcat (lambda (k) (concat "@" k)) remaining-keys " "))
          ;; No refs left, remove property and tag
          (citar-vulpea--set-ref-property nil)
          (vulpea-buffer-tags-remove (list citar-vulpea-keyword)))
        (message "Removed reference: %s" key-to-remove)))))

;;;###autoload
(defun citar-vulpea-dwim ()
  "Smart action for current bibliographic note.
If the current note has references, open citar for those entries.
Otherwise, offer to add a reference."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an org-mode buffer"))
  (let* ((refs (citar-vulpea--get-ref-property))
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
  "Original `citar-notes-source` before enabling `citar-vulpea-mode'.")

(defun citar-vulpea--setup ()
  "Setup citar-vulpea integration."
  (setq citar-vulpea--orig-source citar-notes-source)
  (citar-register-notes-source 'citar-vulpea citar-vulpea-notes-config)
  (if (listp citar-notes-source)
      (add-to-list 'citar-notes-source 'citar-vulpea)
    (setq citar-notes-source 'citar-vulpea)))

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
