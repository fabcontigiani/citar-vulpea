# citar-vulpea

Emacs package integrating [citar](https://github.com/emacs-citar/citar) bibliography management with [vulpea](https://github.com/d12frosted/vulpea) note database.

## Features

- Create bibliography notes from selected citations using Vulpea's note system
- Find notes associated with a citation key
- Citar integration with note indicators and completion
- Add or remove citation references in existing notes

## Installation

### Requirements

- Emacs 27.2+
- [citar](https://github.com/emacs-citar/citar) 1.4+
- [vulpea](https://github.com/d12frosted/vulpea) 2.0+

### Install from source

Clone this repository somewhere on your `load-path`, or use `package-vc-install` if you are on Emacs 29+.

### Configuration

```elisp
(use-package citar-vulpea
  :load-path "/path/to/citar-vulpea"
  :after (citar vulpea)
  :config
  (citar-vulpea-mode 1))
```

## Usage

Enable the integration:

```elisp
(citar-vulpea-mode 1)
```

### Commands

| Command | Description |
|---------|-------------|
| `citar-vulpea-add-reference` | Add a citation reference to current note |
| `citar-vulpea-remove-reference` | Remove a citation reference from current note |
| `citar-vulpea-find-citation` | Find notes citing a reference |
| `citar-vulpea-dwim` | Smart action based on context |

### Creating Notes

With `citar-vulpea-mode` enabled, use `M-x citar-open-notes` or citar's regular interface. When selecting a bibliography entry without an existing note, a new vulpea note will be created with:

- Title derived from the entry (configurable via `citar-vulpea-note-title-template`)
- A refs property containing the citation key so the note can be found again later (default: `ROAM_REFS` for org-roam compatibility; configurable via `citar-vulpea-refs-property`)
- `bib` filetag (configurable via `citar-vulpea-keyword`)

The refs property is the link between a note and one or more citekeys. The package reads that property when searching for notes by citation key.

## Customization

```elisp
;; Tag for bibliographic notes (default: "bib")
(setq citar-vulpea-keyword "bib")

;; Property for storing citation keys (default: "ROAM_REFS" for org-roam compatibility)
(setq citar-vulpea-refs-property "ROAM_REFS")

;; Note title template (default: "${author}, ${title}")
(setq citar-vulpea-note-title-template "${author} (${date}) ${title}")

;; Notes directory (default: nil; uses vulpea-default-notes-directory when unset)
(setq citar-vulpea-notes-directory "references")
```

## Related

- [citar-org-roam](https://github.com/emacs-citar/citar-org-roam) — Similar integration for [org-roam](https://github.com/org-roam/org-roam)
- [citar-denote](https://github.com/pprevos/citar-denote) — Similar integration for [Denote](https://github.com/protesilaos/denote)

## License

GPL-3.0-or-later
