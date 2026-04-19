# citar-vulpea

[![MELPA](https://melpa.org/packages/citar-vulpea-badge.svg)](https://melpa.org/#/citar-vulpea)

Emacs minor mode integrating [citar](https://github.com/emacs-citar/citar) bibliography management with [vulpea](https://github.com/d12frosted/vulpea) note database.

## Features

- **Seamless Note Creation**: Create bibliography notes directly from Citar's completion interface with pre-populated titles and metadata.
- **Reference Tracking**: Automatically manages `REFERENCES` (or custom properties) and `bib` tags, ensuring your notes are always linked to your bibliography.
- **Smart Metadata Management**: Dedicated commands to add/remove citation references at the file-level properties.
- **DWIM Action**: A context-aware command to jump between notes and bibliography entries, or quickly add missing references if none exist.
- **Full Note Integration**: Automatically detect, display, and open associated Vulpea notes directly from Citar's bibliography interface.

## Installation

### Requirements

- Emacs 27.2+
- [citar](https://github.com/emacs-citar/citar) 1.4+
- [vulpea](https://github.com/d12frosted/vulpea) 2.0+

### MELPA

`citar-vulpea` is available on [MELPA](https://melpa.org/). You can install it using `M-x package-install RET citar-vulpea RET`.

### Manual Installation

Clone this repository and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/citar-vulpea")
(require 'citar-vulpea)
```

### Example configuration

```elisp
(use-package citar-vulpea
  :ensure t
  :after (citar vulpea)
  :custom
  ;; Tag used to identify bibliographic notes
  (citar-vulpea-keyword "bib")
  ;; Name of the property used for citation keys
  (citar-vulpea-references-property "REFERENCES")
  ;; Template for new note titles
  (citar-vulpea-note-title-template "${author} (${date}) ${title}")
  ;; Directory to store notes (nil uses vulpea-default-notes-directory)
  (citar-vulpea-notes-directory "~/org/notes/citar")
  :config
  (citar-vulpea-mode 1))
```

## Usage

### Getting Started

Once `citar-vulpea-mode` is enabled, Citar will automatically use Vulpea as a note source. You don't need to change your existing Citar workflow.

*   `M-x citar-open`: When you select "Notes" for an entry, it will open the associated Vulpea note(s) or offer to create one.
*   `M-x citar-open-notes`: Directly find and open notes via Citar's bibliography interface.

### Commands

| Command | Description |
|:--- |:--- |
| `citar-vulpea-add-reference` | Add a citekey to the current note's reference property. |
| `citar-vulpea-remove-reference` | Remove a citekey from the current note's reference property. |
| `citar-vulpea-dwim` | Context-aware jump: Opens the entry in Citar if in a note, or offers to add a reference. |

### How it Works

When you create a note through this package, it:
1.  Generates a title based on your template (e.g., `Author (Year) Title`).
2.  Adds the citekey (prefixed with `@`) to the note's (customizable) reference property.
3.  Tags the note with `bib` (or your custom keyword).

This metadata enables Vulpea to recognize the file as a bibliographic entry, allowing Citar to automatically detect, display, and open your research notes directly from the bibliography interface.

## Related

- [citar-org-roam](https://github.com/emacs-citar/citar-org-roam) — Similar integration for [org-roam](https://github.com/org-roam/org-roam)
- [citar-denote](https://github.com/pprevos/citar-denote) — Similar integration for [Denote](https://github.com/protesilaos/denote)

## License

GPL-3.0-or-later
